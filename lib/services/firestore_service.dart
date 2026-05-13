import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/pending_transaction.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userExpenses(String userId) {
    return _db.collection('users').doc(userId).collection('expenses');
  }

  CollectionReference<Map<String, dynamic>> _userBudgets(String userId) {
    return _db.collection('users').doc(userId).collection('budgets');
  }

  Future<void> addExpense(String userId, Expense expense) async {
    await _userExpenses(userId).add(expense.toMap());
  }

  Stream<List<Expense>> getExpenses(String userId) {
    return _userExpenses(
      userId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Expense.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateExpense(String userId, Expense expense) async {
    if (expense.id == null) return;
    await _userExpenses(userId).doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _userExpenses(userId).doc(expenseId).delete();
  }

  Stream<List<Expense>> getExpensesByMonth(String userId, int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return _userExpenses(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Expense.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  String _monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  Future<double> getMonthlyIncome(String userId, int year, int month) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return 0;
    final data = doc.data();
    if (data == null) return 0;
    final incomeMap = data['monthlyIncome'] as Map<String, dynamic>?;
    if (incomeMap == null) return 0;
    final key = _monthKey(year, month);
    return (incomeMap[key] as num?)?.toDouble() ?? 0;
  }

  Future<void> setMonthlyIncome(
    String userId,
    int year,
    int month,
    double amount,
  ) async {
    final key = _monthKey(year, month);
    await _db.collection('users').doc(userId).set({
      'monthlyIncome': {key: amount},
    }, SetOptions(merge: true));
  }

  Stream<double> streamMonthlyIncome(String userId, int year, int month) {
    final key = _monthKey(year, month);
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      final data = doc.data();
      if (data == null) return 0.0;
      final incomeMap = data['monthlyIncome'] as Map<String, dynamic>?;
      if (incomeMap == null) return 0.0;
      return (incomeMap[key] as num?)?.toDouble() ?? 0.0;
    });
  }

  Future<void> addBudget(String userId, Budget budget) async {
    await _userBudgets(userId).add(budget.toMap());
  }

  Future<void> updateBudget(String userId, Budget budget) async {
    if (budget.id == null) return;
    await _userBudgets(userId).doc(budget.id).update(budget.toMap());
  }

  Future<void> deleteBudget(String userId, String budgetId) async {
    await _userBudgets(userId).doc(budgetId).delete();
  }

  Stream<List<Budget>> getBudgetsByMonth(String userId, int year, int month) {
    return _userBudgets(userId)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Budget.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<Budget>> streamAllBudgets(String userId) {
    return _userBudgets(
      userId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Budget.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  CollectionReference<Map<String, dynamic>> _userGoals(String userId) {
    return _db.collection('users').doc(userId).collection('savingsGoals');
  }

  Future<void> addSavingsGoal(String userId, SavingsGoal goal) async {
    await _userGoals(userId).add(goal.toMap());
  }

  Future<void> updateSavingsGoal(String userId, SavingsGoal goal) async {
    if (goal.id == null) return;
    await _userGoals(userId).doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteSavingsGoal(String userId, String goalId) async {
    await _userGoals(userId).doc(goalId).delete();
  }

  Future<void> addGoalContribution(
    String userId,
    String goalId,
    double amount,
  ) async {
    await _userGoals(
      userId,
    ).doc(goalId).update({'savedAmount': FieldValue.increment(amount)});
  }

  Stream<List<SavingsGoal>> streamSavingsGoals(String userId) {
    return _userGoals(
      userId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SavingsGoal.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  CollectionReference<Map<String, dynamic>> _userPending(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('pendingTransactions');
  }

  Future<void> addPendingTransaction(
    String userId,
    PendingTransaction tx,
  ) async {
    await _userPending(userId).add(tx.toMap());
  }

  Stream<List<PendingTransaction>> streamPendingTransactions(String userId) {
    return _userPending(userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PendingTransaction.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> approvePendingTransaction(
    String userId,
    String txId,
    Expense expense,
  ) async {
    // Add as a real expense
    await addExpense(userId, expense);
    // Mark pending as approved
    await _userPending(userId).doc(txId).update({'status': 'approved'});
  }

  Future<void> dismissPendingTransaction(String userId, String txId) async {
    await _userPending(userId).doc(txId).update({'status': 'dismissed'});
  }
}
