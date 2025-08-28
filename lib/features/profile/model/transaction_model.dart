// lib/features/wallet/model/transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransaction {
  final String id;
  final double amount;
  final String type;
  final String description;
  final Timestamp timestamp;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  // Create WalletTransaction from Firestore DocumentSnapshot
  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return WalletTransaction(
      id: doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'Unknown',
      description: data['description'] ?? 'No description',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  // Convert WalletTransaction to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'description': description,
      'timestamp': timestamp,
    };
  }
}
