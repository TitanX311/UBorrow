class AppConstants {
  static const String appName = "Campus Borrow Hub";
  static const String googleIcon = 'assets/google_icon.svg';
  static const String placeholderImage = "https://via.placeholder.com/150";
}

class AppCollections {
  static const String items = 'items';
  static const String borrowRequests = 'borrow_requests';
  static const String needRequests = 'need_requests';
}

class BorrowRequestStatus {
  static const String pending = 'Pending';
  static const String accepted = 'Accepted';
  static const String declined = 'Declined';
  static const String completed = 'Completed';
}

class NeedRequestStatus {
  static const String open = 'Open';
  static const String matched = 'Matched';
  static const String fulfilled = 'Fulfilled';
  static const String closed = 'Closed';
}