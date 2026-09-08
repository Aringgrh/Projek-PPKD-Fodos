import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function untuk konversi Timestamp Firestore / JSON ke DateTime.
DateTime dateTimeFromJson(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is DateTime) {
    return value;
  } else if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.now();
}

/// Helper function untuk konversi DateTime ke Timestamp Firestore.
dynamic dateTimeToJson(DateTime dateTime) {
  return Timestamp.fromDate(dateTime);
}
