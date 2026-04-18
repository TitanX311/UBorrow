const admin = require("firebase-admin");
const {setGlobalOptions} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const db = admin.firestore();
const messaging = admin.messaging();

const COLLECTIONS = {
  USERS: "users",
  ITEMS: "items",
  BORROW_REQUESTS: "borrow_requests",
  NEED_REQUESTS: "need_requests",
  CHAT_ROOMS: "chat_rooms",
  MESSAGES: "messages",
};

/**
 * Ensures callable requests are authenticated.
 * @param {Object} request
 * @return {string}
 */
function requireAuth(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  return uid;
}

/**
 * Parses a required string input.
 * @param {*} value
 * @param {string} fieldName
 * @return {string}
 */
function parseNonEmptyString(value, fieldName) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${fieldName} is required.`);
  }
  return value.trim();
}

/**
 * Gets a user's FCM token from Firestore.
 * @param {string} uid
 * @return {Promise<string|null>}
 */
async function getUserToken(uid) {
  const doc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
  if (!doc.exists) return null;
  const token = doc.get("fcmToken");
  return typeof token === "string" && token ? token : null;
}

/**
 * Sends a notification to one user if a token exists.
 * @param {string} uid
 * @param {Object} payload
 * @return {Promise<void>}
 */
async function sendNotificationToUser(uid, payload) {
  const token = await getUserToken(uid);
  if (!token) {
    logger.info("No FCM token found, skipping notification.", {uid: uid});
    return;
  }

  try {
    await messaging.send({
      token: token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data || {},
    });
  } catch (error) {
    logger.error("Failed to send FCM notification.", {uid: uid, error: error});
  }
}

exports.saveFcmToken = onCall(async (request) => {
  const uid = requireAuth(request);
  const token = parseNonEmptyString(
      request.data && request.data.token,
      "token",
  );

  await db.collection(COLLECTIONS.USERS).doc(uid).set({
    fcmToken: token,
    fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {success: true};
});

exports.createBorrowRequest = onCall(async (request) => {
  const requesterId = requireAuth(request);
  const data = request.data || {};

  const ownerId = parseNonEmptyString(data.ownerId, "ownerId");
  const itemId = parseNonEmptyString(data.itemId, "itemId");
  const itemName = parseNonEmptyString(data.itemName, "itemName");
  const period = parseNonEmptyString(data.period, "period");

  const itemImage = typeof data.itemImage === "string" ? data.itemImage : "";
  const message = typeof data.message === "string" ? data.message.trim() : "";
  const requesterEmail =
    typeof data.requesterEmail === "string" ? data.requesterEmail : "";
  const ownerEmail = typeof data.ownerEmail === "string" ? data.ownerEmail : "";

  if (ownerId === requesterId) {
    throw new HttpsError(
        "failed-precondition",
        "You cannot borrow your own item.",
    );
  }

  const participantIds = [requesterId, ownerId].sort();
  const chatRoomId = participantIds.join("_");
  const borrowMessage = `I want to borrow this for ${period}`;

  const itemRef = db.collection(COLLECTIONS.ITEMS).doc(itemId);
  const borrowRequestRef = db.collection(COLLECTIONS.BORROW_REQUESTS).doc();
  const chatRoomRef = db.collection(COLLECTIONS.CHAT_ROOMS).doc(chatRoomId);
  const messageRef = chatRoomRef.collection(COLLECTIONS.MESSAGES).doc();

  await db.runTransaction(async (tx) => {
    const itemDoc = await tx.get(itemRef);
    if (!itemDoc.exists) {
      throw new HttpsError("not-found", "Item not found.");
    }

    const itemData = itemDoc.data() || {};
    if (itemData.ownerId !== ownerId) {
      throw new HttpsError("failed-precondition", "Item owner mismatch.");
    }

    if (itemData.available === false) {
      throw new HttpsError("failed-precondition", "Item is not available.");
    }

    tx.set(borrowRequestRef, {
      itemId: itemId,
      itemName: itemName,
      itemImage: itemImage,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
      requesterId: requesterId,
      requesterEmail: requesterEmail,
      period: period,
      message: message,
      status: "Pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(messageRef, {
      senderId: requesterId,
      senderEmail: requesterEmail,
      receiverId: ownerId,
      message: borrowMessage,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      isAutomated: true,
      messageType: "borrow_request",
      borrowRequestId: borrowRequestRef.id,
      itemId: itemId,
      itemName: itemName,
    });

    tx.set(chatRoomRef, {
      participants: participantIds,
      lastMessage: borrowMessage,
      lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
      lastMessageSenderId: requesterId,
      lastMessageType: "borrow_request",
      lastBorrowRequestId: borrowRequestRef.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  await sendNotificationToUser(ownerId, {
    title: "New borrow request",
    body: `${requesterEmail || "A user"} requested ${itemName}.`,
    data: {
      type: "borrow_request",
      itemId: itemId,
      itemName: itemName,
      requesterId: requesterId,
      chatRoomId: chatRoomId,
    },
  });

  return {
    success: true,
    chatRoomId: chatRoomId,
    borrowRequestId: borrowRequestRef.id,
  };
});

exports.markMessagesAsRead = onCall(async (request) => {
  const currentUserId = requireAuth(request);
  const otherUserId = parseNonEmptyString(
      request.data && request.data.otherUserId,
      "otherUserId",
  );

  if (currentUserId === otherUserId) {
    throw new HttpsError("invalid-argument", "otherUserId must be different.");
  }

  const ids = [currentUserId, otherUserId].sort();
  const chatRoomId = ids.join("_");

  const unreadSnapshot = await db
      .collection(COLLECTIONS.CHAT_ROOMS)
      .doc(chatRoomId)
      .collection(COLLECTIONS.MESSAGES)
      .where("senderId", "==", otherUserId)
      .where("receiverId", "==", currentUserId)
      .where("isRead", "==", false)
      .get();

  if (unreadSnapshot.empty) {
    return {success: true, updatedCount: 0};
  }

  const batch = db.batch();
  for (const doc of unreadSnapshot.docs) {
    batch.update(doc.ref, {isRead: true});
  }
  await batch.commit();

  return {success: true, updatedCount: unreadSnapshot.size};
});

exports.onNewMessageCreated = onDocumentCreated(
    `${COLLECTIONS.CHAT_ROOMS}/{chatRoomId}/` +
    `${COLLECTIONS.MESSAGES}/{messageId}`,
    async (event) => {
      const data = event.data && event.data.data();
      if (!data) return;

      const senderId = data.senderId;
      const receiverId = data.receiverId;
      const text =
        typeof data.message === "string" ? data.message : "New message";

      if (!receiverId || senderId === receiverId) return;

      await sendNotificationToUser(receiverId, {
        title: "New message",
        body: text.length > 120 ? `${text.substring(0, 117)}...` : text,
        data: {
          type: "chat_message",
          chatRoomId: event.params.chatRoomId,
          senderId: senderId || "",
        },
      });
    },
);

exports.onNeedRequestCreated = onDocumentCreated(
    `${COLLECTIONS.NEED_REQUESTS}/{requestId}`,
    async (event) => {
      const requestData = event.data && event.data.data();
      if (!requestData) return;

      const requesterId = requestData.requesterId;
      const requesterEmail =
        typeof requestData.requesterEmail === "string" ?
          requestData.requesterEmail :
          "Someone";
      const itemName =
        typeof requestData.itemName === "string" ?
          requestData.itemName :
          "an item";

      if (!requesterId) return;

      const requesterDoc =
        await db.collection(COLLECTIONS.USERS).doc(requesterId).get();
      const requesterHostel =
        requesterDoc.exists ? requesterDoc.get("hostel") : null;

      let usersQuery = db.collection(COLLECTIONS.USERS);
      if (typeof requesterHostel === "string" && requesterHostel) {
        usersQuery = usersQuery.where("hostel", "==", requesterHostel);
      }

      const recipients = await usersQuery.get();
      const messages = [];

      for (const userDoc of recipients.docs) {
        if (userDoc.id === requesterId) continue;
        const token = userDoc.get("fcmToken");
        if (typeof token !== "string" || !token) continue;

        messages.push({
          token: token,
          notification: {
            title: "New need request",
            body: `${requesterEmail} needs ${itemName}.`,
          },
          data: {
            type: "need_request",
            requestId: event.params.requestId,
            requesterId: requesterId,
            itemName: itemName,
          },
        });
      }

      if (messages.length === 0) {
        logger.info("No recipients for need request notification.", {
          requestId: event.params.requestId,
        });
        return;
      }

      for (const messagePayload of messages) {
        try {
          await messaging.send(messagePayload);
        } catch (error) {
          logger.error("Failed sending need request notification.", {
            error: error,
          });
        }
      }
    },
);

