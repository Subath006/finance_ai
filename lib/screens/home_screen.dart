import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/budget.dart';
import '../utils/currency_formatter.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';
import 'edit_expense_screen.dart';
import 'scan_receipt_screen.dart';
import 'insights_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Entertainment': Icons.movie_rounded,
    'Utilities': Icons.bolt_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Health': Icons.favorite_rounded,
    'Education': Icons.school_rounded,
    'Other': Icons.more_horiz_rounded,
  };

  final Map<String, Color> _categoryColors = {
    'Food': const Color(0xFFFF6B6B),
    'Transport': const Color(0xFF4ECDC4),
    'Entertainment': const Color(0xFFFFE66D),
    'Utilities': const Color(0xFF45B7D1),
    'Shopping': const Color(0xFFF7AEF8),
    'Health': const Color(0xFF95E77E),
    'Education': const Color(0xFFDDA0DD),
    'Other': const Color(0xFFB8B8B8),
  };

  void _deleteExpense(String expenseId) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Expense',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this expense?',
          style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteExpense(userId, expenseId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Expense deleted',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF00C9A7),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: const Color(0xFFCF6679)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetIncomeDialog(
    String userId,
    int year,
    int month,
    double currentIncome,
  ) {
    final controller = TextEditingController(
      text: currentIncome > 0 ? currentIncome.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Set Monthly Income',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your income for this month',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9E9E9E),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [CurrencyInputFormatter()],
              autofocus: true,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                prefixText: 'LKR ',
                prefixStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 18,
                ),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(
                stripCommas(controller.text.trim()),
              );
              if (amount == null || amount < 0) return;
              Navigator.pop(ctx);
              await _firestoreService.setMonthlyIncome(
                userId,
                year,
                month,
                amount,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Income updated',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF00C9A7),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: const Color(0xFF00C9A7)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    final userEmail = _authService.currentUser?.email ?? 'User';
    final now = DateTime.now();

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: StreamBuilder<List<Expense>>(
          stream: _firestoreService.getExpenses(userId),
          builder: (context, snapshot) {
            final allExpenses = snapshot.data ?? [];

            final monthExpenses = allExpenses
                .where(
                  (e) => e.date.month == now.month && e.date.year == now.year,
                )
                .toList();
            final totalThisMonth = monthExpenses.fold<double>(
              0,
              (sum, e) => sum + e.amount,
            );
            final expenseCount = monthExpenses.length;

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF9E9E9E),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              userEmail.split('@').first,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Scan Receipt Button
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.document_scanner_rounded,
                              color: Color(0xFF00C9A7),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScanReceiptScreen(),
                                ),
                              );
                            },
                            tooltip: 'Scan Receipt',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: StreamBuilder<double>(
                      stream: _firestoreService.streamMonthlyIncome(
                        userId,
                        now.year,
                        now.month,
                      ),
                      builder: (context, incomeSnap) {
                        final income = incomeSnap.data ?? 0;
                        final balance = income - totalThisMonth;

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This Month',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF9E9E9E),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),

                              InkWell(
                                onTap: () => _showSetIncomeDialog(
                                  userId,
                                  now.year,
                                  now.month,
                                  income,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF00C9A7,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_downward_rounded,
                                        color: Color(0xFF00C9A7),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Income',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF9E9E9E),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'LKR ${formatCurrency(income)}',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF00C9A7),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.edit_rounded,
                                      color: Color(0xFF616161),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFCF6679,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Color(0xFFCF6679),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Expenses',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF9E9E9E),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'LKR ${formatCurrency(totalThisMonth)}',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFCF6679),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Color(0xFF2C2C2C),
                                  height: 1,
                                ),
                              ),

                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          (balance >= 0
                                                  ? const Color(0xFF00C9A7)
                                                  : const Color(0xFFCF6679))
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: balance >= 0
                                          ? const Color(0xFF00C9A7)
                                          : const Color(0xFFCF6679),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Balance',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'LKR ${formatCurrency(balance)}',
                                    style: GoogleFonts.poppins(
                                      color: balance >= 0
                                          ? const Color(0xFF00C9A7)
                                          : const Color(0xFFCF6679),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _miniStat(
                                    Icons.receipt_long_rounded,
                                    '$expenseCount expenses',
                                  ),
                                  const SizedBox(width: 20),
                                  _miniStat(
                                    Icons.calendar_today_rounded,
                                    DateFormat('MMMM yyyy').format(now),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: StreamBuilder<List<Budget>>(
                    stream: _firestoreService.getBudgetsByMonth(
                      userId,
                      now.year,
                      now.month,
                    ),
                    builder: (context, budgetSnap) {
                      final budgets = budgetSnap.data ?? [];
                      if (budgets.isEmpty) return const SizedBox.shrink();

                      final Map<String, double> catSpend = {};
                      for (final e in monthExpenses) {
                        catSpend[e.category] =
                            (catSpend[e.category] ?? 0) + e.amount;
                      }

                      final alerts =
                          budgets.where((b) {
                            final spent = b.category == 'Overall'
                                ? totalThisMonth
                                : (catSpend[b.category] ?? 0);
                            return b.limitAmount > 0 &&
                                spent / b.limitAmount >= 0.8;
                          }).toList()..sort((a, b) {
                            final sa = a.category == 'Overall'
                                ? totalThisMonth
                                : (catSpend[a.category] ?? 0);
                            final sb = b.category == 'Overall'
                                ? totalThisMonth
                                : (catSpend[b.category] ?? 0);
                            final pa = a.limitAmount > 0
                                ? sa / a.limitAmount
                                : 0.0;
                            final pb = b.limitAmount > 0
                                ? sb / b.limitAmount
                                : 0.0;
                            return pb.compareTo(pa);
                          });

                      if (alerts.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Column(
                          children: alerts.map((b) {
                            final spent = b.category == 'Overall'
                                ? totalThisMonth
                                : (catSpend[b.category] ?? 0);
                            final pct = spent / b.limitAmount;
                            final isOver = pct >= 1.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BudgetScreen(),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isOver
                                                ? const Color(0xFFCF6679)
                                                : const Color(0xFFFFB74D))
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                          (isOver
                                                  ? const Color(0xFFCF6679)
                                                  : const Color(0xFFFFB74D))
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isOver
                                            ? Icons.error_rounded
                                            : Icons.warning_rounded,
                                        color: isOver
                                            ? const Color(0xFFCF6679)
                                            : const Color(0xFFFFB74D),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          isOver
                                              ? '${b.category} budget exceeded! (${(pct * 100).toStringAsFixed(0)}%)'
                                              : '${b.category}: ${(pct * 100).toStringAsFixed(0)}% of budget used',
                                          style: GoogleFonts.poppins(
                                            color: isOver
                                                ? const Color(0xFFCF6679)
                                                : const Color(0xFFFFB74D),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: isOver
                                            ? const Color(0xFFCF6679)
                                            : const Color(0xFFFFB74D),
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: StreamBuilder<double>(
                      stream: _firestoreService.streamMonthlyIncome(
                        userId,
                        now.year,
                        now.month,
                      ),
                      builder: (context, incSnap) {
                        final inc = incSnap.data ?? 0;
                        return Material(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InsightsScreen(
                                    income: inc,
                                    expenses: totalThisMonth,
                                    savings: inc - totalThisMonth,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFFE66D,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.lightbulb_rounded,
                                      color: Color(0xFFFFE66D),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'View Investment Insights',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Color(0xFFFFE66D),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Expenses',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${allExpenses.length} total',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF9E9E9E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (allExpenses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            size: 64,
                            color: Color(0xFF2C2C2C),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses yet',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF9E9E9E),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add your first expense',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF616161),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final expense = allExpenses[index];
                      final color =
                          _categoryColors[expense.category] ?? Colors.grey;
                      final icon =
                          _categoryIcons[expense.category] ?? Icons.circle;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        child: Dismissible(
                          key: Key(expense.id ?? index.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFCF6679,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Color(0xFFCF6679),
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (expense.id != null) {
                              _deleteExpense(expense.id!);
                            }
                            return false;
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditExpenseScreen(expense: expense),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: color, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.description.isEmpty
                                              ? expense.category
                                              : expense.description,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${expense.category} • ${DateFormat('MMM d').format(expense.date)}',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF9E9E9E),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '-LKR ${formatCurrency(expense.amount)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF616161),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: allExpenses.length),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        backgroundColor: const Color(0xFF00C9A7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF9E9E9E), size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: const Color(0xFF9E9E9E),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
