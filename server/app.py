from __future__ import annotations

import argparse
import hashlib
import json
import logging
import os
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore, messaging
from google.api_core.exceptions import AlreadyExists

CHECKPOINT_COLLECTION = 'notification_meta'
CHECKPOINT_DOC = 'firestore_poll'
EVENT_LOG_COLLECTION = 'notification_events'

NEED_STATUS_FULFILLED = 'Fulfilled'
BORROW_STATUS_PENDING = 'Pending'
BORROW_STATUS_ACCEPTED = 'Accepted'
BORROW_STATUS_DECLINED = 'Declined'
BORROW_STATUS_COMPLETED = 'Completed'


def _utc_now() -> datetime:
	return datetime.now(timezone.utc)


def _to_utc_datetime(value: Any) -> datetime | None:
	if value is None:
		return None

	if isinstance(value, datetime):
		if value.tzinfo is None:
			return value.replace(tzinfo=timezone.utc)
		return value.astimezone(timezone.utc)

	if isinstance(value, str):
		try:
			parsed = datetime.fromisoformat(value.replace('Z', '+00:00'))
			if parsed.tzinfo is None:
				return parsed.replace(tzinfo=timezone.utc)
			return parsed.astimezone(timezone.utc)
		except ValueError:
			return None

	return None


def _to_iso(value: datetime) -> str:
	return value.astimezone(timezone.utc).isoformat()


def _build_event_id(parts: list[str]) -> str:
	raw = '|'.join(parts)
	return hashlib.sha256(raw.encode('utf-8')).hexdigest()


def _to_data_map(payload: dict[str, Any]) -> dict[str, str]:
	data: dict[str, str] = {}
	for key, value in payload.items():
		if value is None:
			continue
		data[key] = str(value)
	return data


@dataclass
class WorkerConfig:
	max_docs_per_run: int = 200
	max_sends_per_run: int = 100
	max_retry_attempts: int = 3
	poll_interval_seconds: int = 300

	@staticmethod
	def from_env() -> 'WorkerConfig':
		return WorkerConfig(
			max_docs_per_run=int(os.getenv('MAX_DOCS_PER_RUN', '200')),
			max_sends_per_run=int(os.getenv('MAX_SENDS_PER_RUN', '100')),
			max_retry_attempts=int(os.getenv('MAX_RETRY_ATTEMPTS', '3')),
			poll_interval_seconds=int(os.getenv('POLL_INTERVAL_SECONDS', '300')),
		)


class NotificationWorker:
	def __init__(self, db: firestore.Client, config: WorkerConfig) -> None:
		self.db = db
		self.config = config
		self.send_count = 0
		self.event_count = 0
		self.retry_count = 0

	def run_once(self) -> None:
		started_at = _utc_now()
		checkpoint = self._load_checkpoint()
		updated_checkpoint = dict(checkpoint)

		logging.info('Starting notification poll run')

		updated_checkpoint['need_requests_updated_at'] = self._process_need_requests(
			checkpoint['need_requests_updated_at']
		)
		updated_checkpoint['borrow_requests_updated_at'] = self._process_borrow_requests(
			checkpoint['borrow_requests_updated_at']
		)
		updated_checkpoint['chat_messages_timestamp'] = self._process_chat_messages(
			checkpoint['chat_messages_timestamp']
		)

		self._save_checkpoint(updated_checkpoint)

		elapsed = (_utc_now() - started_at).total_seconds()
		logging.info(
			'Poll run completed | events=%s sent=%s retries=%s elapsed_sec=%.2f',
			self.event_count,
			self.send_count,
			self.retry_count,
			elapsed,
		)

	def _load_checkpoint(self) -> dict[str, datetime]:
		default_time = datetime(1970, 1, 1, tzinfo=timezone.utc)
		snapshot = (
			self.db.collection(CHECKPOINT_COLLECTION).doc(CHECKPOINT_DOC).get()
		)

		if not snapshot.exists:
			return {
				'need_requests_updated_at': default_time,
				'borrow_requests_updated_at': default_time,
				'chat_messages_timestamp': default_time,
			}

		data = snapshot.to_dict() or {}
		return {
			'need_requests_updated_at': _to_utc_datetime(
				data.get('need_requests_updated_at')
			)
			or default_time,
			'borrow_requests_updated_at': _to_utc_datetime(
				data.get('borrow_requests_updated_at')
			)
			or default_time,
			'chat_messages_timestamp': _to_utc_datetime(
				data.get('chat_messages_timestamp')
			)
			or default_time,
		}

	def _save_checkpoint(self, checkpoint: dict[str, datetime]) -> None:
		self.db.collection(CHECKPOINT_COLLECTION).doc(CHECKPOINT_DOC).set(
			{
				'need_requests_updated_at': _to_iso(
					checkpoint['need_requests_updated_at']
				),
				'borrow_requests_updated_at': _to_iso(
					checkpoint['borrow_requests_updated_at']
				),
				'chat_messages_timestamp': _to_iso(checkpoint['chat_messages_timestamp']),
				'updatedAt': firestore.SERVER_TIMESTAMP,
			},
			merge=True,
		)

	def _process_need_requests(self, since: datetime) -> datetime:
		latest_seen = since
		query = (
			self.db.collection('need_requests')
			.where('updatedAt', '>', since)
			.order_by('updatedAt')
			.limit(self.config.max_docs_per_run)
		)

		for doc in query.stream():
			data = doc.to_dict() or {}
			updated_at = _to_utc_datetime(data.get('updatedAt'))
			created_at = _to_utc_datetime(data.get('createdAt'))
			fulfilled_at = _to_utc_datetime(data.get('fulfilledAt'))

			if updated_at and updated_at > latest_seen:
				latest_seen = updated_at

			if self._send_limit_reached():
				break

			item_name = (data.get('itemName') or 'Requested item').strip()
			requester_id = (data.get('requesterId') or '').strip()
			requester_email = (data.get('requesterEmail') or 'Someone').strip()
			request_id = doc.id

			if (
				created_at
				and created_at > since
				and requester_id
			):
				for user_id in self._list_all_user_ids_except(requester_id):
					self._emit_event(
						event_type='need_request_created',
						source_path=doc.reference.path,
						source_time=created_at,
						recipient_id=user_id,
						title='New Need Request',
						body=f'{requester_email} needs: {item_name}',
						data={
							'type': 'need_request',
							'requestId': request_id,
							'itemName': item_name,
						},
					)

			if (
				(data.get('status') == NEED_STATUS_FULFILLED)
				and fulfilled_at
				and fulfilled_at > since
				and requester_id
			):
				self._emit_event(
					event_type='need_request_fulfilled',
					source_path=doc.reference.path,
					source_time=fulfilled_at,
					recipient_id=requester_id,
					title='Need Request Fulfilled',
					body=f'Your request for "{item_name}" was fulfilled.',
					data={
						'type': 'request_status',
						'requestId': request_id,
						'status': 'fulfilled',
					},
				)

		return latest_seen

	def _process_borrow_requests(self, since: datetime) -> datetime:
		latest_seen = since
		query = (
			self.db.collection('borrow_requests')
			.where('updatedAt', '>', since)
			.order_by('updatedAt')
			.limit(self.config.max_docs_per_run)
		)

		for doc in query.stream():
			data = doc.to_dict() or {}
			updated_at = _to_utc_datetime(data.get('updatedAt'))
			created_at = _to_utc_datetime(data.get('createdAt'))

			if updated_at and updated_at > latest_seen:
				latest_seen = updated_at

			if self._send_limit_reached():
				break

			item_name = (data.get('itemName') or 'Item').strip()
			requester_email = (data.get('requesterEmail') or 'Someone').strip()
			owner_id = (data.get('ownerId') or '').strip()
			requester_id = (data.get('requesterId') or '').strip()
			status = (data.get('status') or BORROW_STATUS_PENDING).strip()

			if created_at and created_at > since and owner_id:
				self._emit_event(
					event_type='borrow_request_created',
					source_path=doc.reference.path,
					source_time=created_at,
					recipient_id=owner_id,
					title='New Borrow Request',
					body=f'{requester_email} requested "{item_name}".',
					data={
						'type': 'borrow_request',
						'requestId': doc.id,
						'itemName': item_name,
					},
				)

			if (
				updated_at
				and updated_at > since
				and requester_id
				and status in {
					BORROW_STATUS_ACCEPTED,
					BORROW_STATUS_DECLINED,
					BORROW_STATUS_COMPLETED,
				}
			):
				self._emit_event(
					event_type='borrow_request_status_changed',
					source_path=doc.reference.path,
					source_time=updated_at,
					recipient_id=requester_id,
					title='Borrow Request Update',
					body=f'Your request for "{item_name}" is now {status}.',
					data={
						'type': 'request_status',
						'requestId': doc.id,
						'status': status,
						'itemName': item_name,
					},
				)

		return latest_seen

	def _process_chat_messages(self, since: datetime) -> datetime:
		latest_seen = since
		query = (
			self.db.collection_group('messages')
			.where('timestamp', '>', since)
			.order_by('timestamp')
			.limit(self.config.max_docs_per_run)
		)

		for doc in query.stream():
			data = doc.to_dict() or {}
			message_time = _to_utc_datetime(data.get('timestamp'))
			receiver_id = (data.get('receiverId') or '').strip()
			sender_id = (data.get('senderId') or '').strip()

			if message_time and message_time > latest_seen:
				latest_seen = message_time

			if self._send_limit_reached():
				break

			if not message_time or not receiver_id or sender_id == receiver_id:
				continue

			self._emit_event(
				event_type='chat_message_created',
				source_path=doc.reference.path,
				source_time=message_time,
				recipient_id=receiver_id,
				title='New Message',
				body=(data.get('message') or 'You have a new message').strip(),
				data={
					'type': 'message',
					'chatId': doc.reference.parent.parent.id if doc.reference.parent.parent else '',
					'senderId': sender_id,
				},
			)

		return latest_seen

	def _send_limit_reached(self) -> bool:
		return self.send_count >= self.config.max_sends_per_run

	def _list_all_user_ids_except(self, exclude_user_id: str) -> list[str]:
		user_ids: list[str] = []
		for user_doc in self.db.collection('users').stream():
			if user_doc.id != exclude_user_id:
				user_ids.append(user_doc.id)
				if len(user_ids) >= self.config.max_sends_per_run:
					break
		return user_ids

	def _emit_event(
		self,
		*,
		event_type: str,
		source_path: str,
		source_time: datetime,
		recipient_id: str,
		title: str,
		body: str,
		data: dict[str, Any],
	) -> None:
		if self._send_limit_reached():
			return

		event_id = _build_event_id(
			[
				event_type,
				source_path,
				_to_iso(source_time),
				recipient_id,
			]
		)

		event_doc_ref = self.db.collection(EVENT_LOG_COLLECTION).doc(event_id)
		try:
			event_doc_ref.create(
				{
					'eventType': event_type,
					'sourcePath': source_path,
					'recipientId': recipient_id,
					'status': 'pending',
					'createdAt': firestore.SERVER_TIMESTAMP,
				}
			)
		except AlreadyExists:
			return

		self.event_count += 1

		success, message_id, error_text = self._send_with_retry(
			recipient_id=recipient_id,
			title=title,
			body=body,
			data=data,
		)

		if success:
			self.send_count += 1

		event_doc_ref.set(
			{
				'title': title,
				'body': body,
				'data': _to_data_map(data),
				'status': 'sent' if success else 'failed',
				'messageId': message_id,
				'error': error_text,
				'updatedAt': firestore.SERVER_TIMESTAMP,
			},
			merge=True,
		)

	def _send_with_retry(
		self,
		*,
		recipient_id: str,
		title: str,
		body: str,
		data: dict[str, Any],
	) -> tuple[bool, str | None, str | None]:
		token = self._get_user_fcm_token(recipient_id)
		if not token:
			return False, None, 'missing_fcm_token'

		payload_data = _to_data_map(data)

		for attempt in range(1, self.config.max_retry_attempts + 1):
			try:
				msg = messaging.Message(
					token=token,
					notification=messaging.Notification(title=title, body=body),
					data=payload_data,
					android=messaging.AndroidConfig(priority='high'),
					apns=messaging.APNSConfig(
						headers={'apns-priority': '10'}
					),
				)
				message_id = messaging.send(msg)
				return True, message_id, None
			except Exception as exc:
				error_text = str(exc)
				self.retry_count += 1

				if self._is_token_invalid_error(error_text):
					self._clear_user_fcm_token(recipient_id)
					return False, None, error_text

				if attempt >= self.config.max_retry_attempts:
					return False, None, error_text

				sleep_seconds = 2 ** (attempt - 1)
				time.sleep(sleep_seconds)

		return False, None, 'unknown_send_error'

	def _get_user_fcm_token(self, user_id: str) -> str | None:
		snapshot = self.db.collection('users').doc(user_id).get()
		if not snapshot.exists:
			return None

		data = snapshot.to_dict() or {}
		token = (data.get('fcmToken') or '').strip()
		return token or None

	def _clear_user_fcm_token(self, user_id: str) -> None:
		self.db.collection('users').doc(user_id).set(
			{
				'fcmToken': firestore.DELETE_FIELD,
				'updatedAt': firestore.SERVER_TIMESTAMP,
			},
			merge=True,
		)

	@staticmethod
	def _is_token_invalid_error(error_text: str) -> bool:
		lowered = error_text.lower()
		return (
			'registration token is not a valid fcm registration token' in lowered
			or 'requested entity was not found' in lowered
			or 'registration-token-not-registered' in lowered
			or 'unregistered' in lowered
		)


def init_firebase() -> firestore.Client:
	if not firebase_admin._apps:
		service_account_json = os.getenv('FIREBASE_SERVICE_ACCOUNT_JSON')
		service_account_file = os.getenv('FIREBASE_SERVICE_ACCOUNT_FILE')

		if service_account_json:
			cred_data = json.loads(service_account_json)
			cred = credentials.Certificate(cred_data)
			firebase_admin.initialize_app(cred)
		elif service_account_file:
			cred = credentials.Certificate(service_account_file)
			firebase_admin.initialize_app(cred)
		else:
			cred = credentials.ApplicationDefault()
			firebase_admin.initialize_app(cred)

	return firestore.client()


def main() -> None:
	parser = argparse.ArgumentParser(description='UBorrow notification poll worker')
	parser.add_argument('--run-once', action='store_true', help='Run a single poll cycle and exit')
	args = parser.parse_args()

	logging.basicConfig(
		level=logging.INFO,
		format='%(asctime)s %(levelname)s %(message)s',
	)

	db = init_firebase()
	config = WorkerConfig.from_env()
	worker = NotificationWorker(db, config)

	if args.run_once:
		worker.run_once()
		return

	while True:
		worker.run_once()
		time.sleep(config.poll_interval_seconds)


if __name__ == '__main__':
	main()
