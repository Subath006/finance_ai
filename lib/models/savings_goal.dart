import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoal {
  final String? id;
  final String userId;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final String icon;
  final DateTime createdAt;
  final DateTime? deadline;

  SavingsGoal({
    this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0,
    this.icon = 'savings',
    this.deadline,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;

  double get remaining =>
      (targetAmount - savedAmount).clamp(0, double.infinity);

  bool get isCompleted => savedAmount >= targetAmount;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'icon': icon,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SavingsGoal.fromMap(String id, Map<String, dynamic> map) {
    return SavingsGoal(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0,
      icon: map['icon'] ?? 'savings',
      deadline: (map['deadline'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? savedAmount,
    String? icon,
    DateTime? deadline,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      icon: icon ?? this.icon,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
    );
  }
}
