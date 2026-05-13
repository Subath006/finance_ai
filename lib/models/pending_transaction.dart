import 'package:cloud_firestore/cloud_firestore.dart';

class PendingTransaction {
  final String? id;
  final String userId;
  final double amount;
  final String? vendor;
  final String? category;
  final String? cardLast4;
  final String rawSms;
  final DateTime detectedAt;
  final String status; // 'pending', 'approved', 'dismissed'

  PendingTransaction({
    this.id,
    required this.userId,
    required this.amount,
    this.vendor,
    this.category,
    this.cardLast4,
    required this.rawSms,
    required this.detectedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'vendor': vendor,
      'category': category,
      'cardLast4': cardLast4,
      'rawSms': rawSms,
      'detectedAt': Timestamp.fromDate(detectedAt),
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory PendingTransaction.fromMap(String id, Map<String, dynamic> map) {
    return PendingTransaction(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      vendor: map['vendor'] as String?,
      category: map['category'] as String?,
      cardLast4: map['cardLast4'] as String?,
      rawSms: map['rawSms'] ?? '',
      detectedAt:
          (map['detectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  PendingTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? vendor,
    String? category,
    String? cardLast4,
    String? rawSms,
    DateTime? detectedAt,
    String? status,
  }) {
    return PendingTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      vendor: vendor ?? this.vendor,
      category: category ?? this.category,
      cardLast4: cardLast4 ?? this.cardLast4,
      rawSms: rawSms ?? this.rawSms,
      detectedAt: detectedAt ?? this.detectedAt,
      status: status ?? this.status,
    );
  }
}
