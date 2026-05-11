import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String? id;
  final String userId;
  final String category;
  final double limitAmount;
  final int month;
  final int year;
  final DateTime createdAt;

  Budget({
    this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.month,
    required this.year,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'limitAmount': limitAmount,
      'month': month,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Budget.fromMap(String id, Map<String, dynamic> map) {
    return Budget(
      id: id,
      userId: map['userId'] ?? '',
      category: map['category'] ?? 'Overall',
      limitAmount: (map['limitAmount'] as num?)?.toDouble() ?? 0,
      month: (map['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Budget copyWith({
    String? id,
    String? userId,
    String? category,
    double? limitAmount,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt,
    );
  }
}
