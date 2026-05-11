import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/currency_formatter.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  final List<String> _categories = [
    'Overall',
    'Food',
    'Transport',
    'Entertainment',
    'Utilities',
    'Shopping',
    'Health',
    'Education',
    'Other',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Overall': Icons.account_balance_wallet_rounded,
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
    'Overall': const Color(0xFF00C9A7),
    'Food': const Color(0xFFFF6B6B),
    'Transport': const Color(0xFF4ECDC4),
    'Entertainment': const Color(0xFFFFE66D),
    'Utilities': const Color(0xFF45B7D1),
    'Shopping': const Color(0xFFF7AEF8),
    'Health': const Color(0xFF95E77E),
    'Education': const Color(0xFFDDA0DD),
    'Other': const Color(0xFFB8B8B8),
  };

  void _showCreateBudgetDialog(String userId, {Budget? existing}) {
    final now = DateTime.now();
    String selectedCategory = existing?.category ?? 'Overall';
    final limitController = TextEditingController(
      text: existing != null ? existing.limitAmount.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF616161),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      existing != null ? 'Edit Budget' : 'Create Budget',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set a spending limit for ${DateFormat('MMMM yyyy').format(now)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9E9E9E),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category selector
                    Text(
                      'Category',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9E9E9E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final isSelected = cat == selectedCategory;
                          final color = _categoryColors[cat] ?? Colors.grey;
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.2)
                                    : const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected ? color : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _categoryIcons[cat],
                                    color: isSelected
                                        ? color
                                        : const Color(0xFF9E9E9E),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat,
                                    style: GoogleFonts.poppins(
                                      color: isSelected
                                          ? color
                                          : const Color(0xFF9E9E9E),
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount field
                    Text(
                      'Spending Limit',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9E9E9E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: limitController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter()],
                      autofocus: existing == null,
                      style:
                          GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        prefixText: 'LKR ',
                        prefixStyle: GoogleFonts.poppins(
                            color: const Color(0xFF9E9E9E), fontSize: 18),
                        hintText: '0.00',
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount =
                              double.tryParse(stripCommas(limitController.text.trim()));
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Enter a valid amount',
                                    style: GoogleFonts.poppins()),
                                backgroundColor: const Color(0xFFCF6679),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx);

                          if (existing != null) {
                            await _firestoreService.updateBudget(
                              userId,
                              existing.copyWith(
                                category: selectedCategory,
                                limitAmount: amount,
                              ),
                            );
                          } else {
                            await _firestoreService.addBudget(
                              userId,
                              Budget(
                                userId: userId,
                                category: selectedCategory,
                                limitAmount: amount,
                                month: now.month,
                                year: now.year,
                              ),
                            );
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  existing != null
                                      ? 'Budget updated'
                                      : 'Budget created',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: const Color(0xFF00C9A7),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9A7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          existing != null ? 'Update Budget' : 'Create Budget',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteBudget(String userId, String budgetId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Budget',
            style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('Remove this spending limit?',
            style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteBudget(userId, budgetId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Budget deleted', style: GoogleFonts.poppins()),
                    backgroundColor: const Color(0xFF00C9A7),
                  ),
                );
              }
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(color: const Color(0xFFCF6679))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    final now = DateTime.now();

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: StreamBuilder<List<Budget>>(
          stream:
              _firestoreService.getBudgetsByMonth(userId, now.year, now.month),
          builder: (context, budgetSnap) {
            final budgets = budgetSnap.data ?? [];

            return StreamBuilder<List<Expense>>(
              stream: _firestoreService.getExpenses(userId),
              builder: (context, expenseSnap) {
                final allExpenses = expenseSnap.data ?? [];
                final monthExpenses = allExpenses
                    .where((e) =>
                        e.date.month == now.month && e.date.year == now.year)
                    .toList();
                final totalSpent = monthExpenses.fold<double>(
                    0, (sum, e) => sum + e.amount);

                // Build category spend map
                final Map<String, double> categorySpend = {};
                for (final e in monthExpenses) {
                  categorySpend[e.category] =
                      (categorySpend[e.category] ?? 0) + e.amount;
                }

                // Sort: over-budget first, then by percentage descending
                final sortedBudgets = List<Budget>.from(budgets)..sort((a, b) {
                  final spentA = a.category == 'Overall'
                      ? totalSpent
                      : (categorySpend[a.category] ?? 0);
                  final spentB = b.category == 'Overall'
                      ? totalSpent
                      : (categorySpend[b.category] ?? 0);
                  final pctA = a.limitAmount > 0 ? spentA / a.limitAmount : 0;
                  final pctB = b.limitAmount > 0 ? spentB / b.limitAmount : 0;
                  return pctB.compareTo(pctA);
                });

                // Count alerts
                final alertCount = budgets.where((b) {
                  final spent = b.category == 'Overall'
                      ? totalSpent
                      : (categorySpend[b.category] ?? 0);
                  return b.limitAmount > 0 && spent / b.limitAmount >= 0.8;
                }).length;

                return CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Budgets',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMMM yyyy').format(now),
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF9E9E9E),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (alertCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCF6679)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_rounded,
                                        color: Color(0xFFCF6679), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$alertCount alert${alertCount > 1 ? 's' : ''}',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFFCF6679),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Summary card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              _summaryTile(
                                'Active Budgets',
                                budgets.length.toString(),
                                Icons.savings_rounded,
                                const Color(0xFF00C9A7),
                              ),
                              const SizedBox(width: 16),
                              _summaryTile(
                                'Total Spent',
                                'LKR ${formatCurrencyWhole(totalSpent)}',
                                Icons.trending_up_rounded,
                                const Color(0xFFFF6B6B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Budget list header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                        child: Text(
                          'Spending Limits',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Budget items or empty state
                    if (sortedBudgets.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 40),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C9A7)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(Icons.savings_rounded,
                                    color: Color(0xFF00C9A7), size: 36),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No budgets yet',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF9E9E9E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Create a budget to track your\nspending limits',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF616161),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showCreateBudgetDialog(userId),
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: Text('Create Budget',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final budget = sortedBudgets[index];
                            final spent = budget.category == 'Overall'
                                ? totalSpent
                                : (categorySpend[budget.category] ?? 0);
                            final pct = budget.limitAmount > 0
                                ? spent / budget.limitAmount
                                : 0.0;
                            final color =
                                _categoryColors[budget.category] ?? Colors.grey;
                            final icon =
                                _categoryIcons[budget.category] ?? Icons.circle;

                            Color progressColor;
                            String statusText;
                            if (pct >= 1.0) {
                              progressColor = const Color(0xFFCF6679);
                              statusText = 'Over budget!';
                            } else if (pct >= 0.8) {
                              progressColor = const Color(0xFFFFB74D);
                              statusText = 'Almost there';
                            } else {
                              progressColor = const Color(0xFF00C9A7);
                              statusText = 'On track';
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 5),
                              child: Dismissible(
                                key: Key(budget.id ?? index.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCF6679)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                      color: Color(0xFFCF6679)),
                                ),
                                confirmDismiss: (direction) async {
                                  if (budget.id != null) {
                                    _deleteBudget(userId, budget.id!);
                                  }
                                  return false;
                                },
                                child: GestureDetector(
                                  onTap: () => _showCreateBudgetDialog(userId,
                                      existing: budget),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(16),
                                      border: pct >= 1.0
                                          ? Border.all(
                                              color: const Color(0xFFCF6679)
                                                  .withValues(alpha: 0.4),
                                              width: 1)
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: color
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(icon,
                                                  color: color, size: 22),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    budget.category,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: progressColor,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        statusText,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: progressColor,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${(pct * 100).clamp(0, 999).toStringAsFixed(0)}%',
                                                  style: GoogleFonts.poppins(
                                                    color: progressColor,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'of LKR ${formatCurrency(budget.limitAmount)}',
                                                  style: GoogleFonts.poppins(
                                                    color:
                                                        const Color(0xFF9E9E9E),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        // Progress bar
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct.clamp(0.0, 1.0),
                                            minHeight: 6,
                                            backgroundColor:
                                                const Color(0xFF2C2C2C),
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                                    progressColor),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'LKR ${formatCurrency(spent)}',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'LKR ${formatCurrency(budget.limitAmount)}',
                                              style: GoogleFonts.poppins(
                                                color:
                                                    const Color(0xFF9E9E9E),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: sortedBudgets.length,
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBudgetDialog(userId),
        backgroundColor: const Color(0xFF00C9A7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _summaryTile(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9E9E9E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
