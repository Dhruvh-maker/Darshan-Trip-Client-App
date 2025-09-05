import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Safely parse Firestore Timestamp, DateTime or null into DateTime
DateTime parseFirestoreDate(dynamic value) {
  if (value is Timestamp) return value.toDate(); // Firestore Timestamp
  if (value is DateTime) return value; // Already DateTime
  return DateTime.now(); // Fallback if null/FieldValue
}

/// Format Firestore Timestamp/DateTime into a string
String formatFirestoreDate(
  dynamic value, {
  String pattern = 'dd/MM/yyyy HH:mm',
}) {
  final date = parseFirestoreDate(value);
  return DateFormat(pattern).format(date);
}
