import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function untuk konversi Timestamp Firestore / JSON ke DateTime non-nullable.
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

/// Helper function untuk konversi Timestamp Firestore / JSON ke DateTime nullable.
DateTime? dateTimeFromJsonNullable(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is DateTime) {
    return value;
  } else if (value is String) {
    return DateTime.tryParse(value);
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

/// Helper function untuk konversi DateTime ke Timestamp Firestore.
dynamic dateTimeToJson(DateTime? dateTime) {
  if (dateTime == null) return null;
  return Timestamp.fromDate(dateTime);
}

/// Helper konversi nilai dinamis ke double secara aman (mendukung int, double, num, string).
double doubleFromDynamic(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper konversi nilai dinamis ke int secara aman.
int intFromDynamic(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}
