import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/currency_formatter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  DateTime _selectedMonth = DateTime.now();

  final List<Color> _chartColors = const [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF45B7D1),
    Color(0xFFF7AEF8),
    Color(0xFF95E77E),
    Color(0xFFDDA0DD),
    Color(0xFFB8B8B8),
  ];

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

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

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
                .where((e) =>
                    e.date.month == _selectedMonth.month &&
                    e.date.year == _selectedMonth.year)
                .toList();

            if (monthExpenses.isEmpty) {
              return _buildEmptyState();
            }

            final total =
                monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
            final daysInMonth = DateTime(
                    _selectedMonth.year, _selectedMonth.month + 1, 0)
                .day;
            final avgPerDay = total / daysInMonth;

            // Category totals
            final catTotals = <String, double>{};
            for (final e in monthExpenses) {
              catTotals[e.category] =
                  (catTotals[e.category] ?? 0) + e.amount;
            }
            final sortedCats = catTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return StreamBuilder<double>(
              stream: _firestoreService.streamMonthlyIncome(
                  userId, _selectedMonth.year, _selectedMonth.month),
              builder: (context, incomeSnap) {
                final income = incomeSnap.data ?? 0;
                final balance = income - total;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text('Statistics',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      // Month Selector
                      _buildMonthSelector(),
                      const SizedBox(height: 20),

                      // Income / Balance Row
                      Row(
                        children: [
                          Expanded(
                              child: _statCard(
                                  'Income',
                                  'LKR ${formatCurrency(income)}',
                                  Icons.arrow_downward_rounded,
                                  const Color(0xFF00C9A7))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _statCard(
                                  'Balance',
                                  'LKR ${formatCurrency(balance)}',
                                  Icons.account_balance_wallet_rounded,
                                  balance >= 0
                                      ? const Color(0xFF00C9A7)
                                      : const Color(0xFFCF6679))),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stats Row
                      _buildStatsRow(total, avgPerDay, monthExpenses.length),
                      const SizedBox(height: 24),

                      // Pie Chart
                      _buildPieChart(catTotals, total),
                      const SizedBox(height: 24),

                      // Bar Chart
                      _buildBarChart(monthExpenses),
                      const SizedBox(height: 24),

                      // Category List
                      _buildCategoryList(sortedCats, total),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statistics',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildMonthSelector(),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined,
                    size: 64, color: Color(0xFF2C2C2C)),
                const SizedBox(height: 16),
                Text('No expenses this month',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF9E9E9E), fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: Colors.white70),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: Colors.white70),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(double total, double avgPerDay, int count) {
    return Row(
      children: [
        Expanded(
            child: _statCard('Total Spent',
                'LKR ${formatCurrency(total)}',
                Icons.account_balance_wallet_rounded, const Color(0xFF00C9A7))),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard('Avg/Day',
                'LKR ${formatCurrency(avgPerDay)}',
                Icons.trending_up_rounded, const Color(0xFF45B7D1))),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard('Count', '$count',
                Icons.receipt_long_rounded, const Color(0xFFFFE66D))),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> catTotals, double total) {
    final categories = catTotals.keys.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 220,
        child: PieChart(
          PieChartData(
            sections: List.generate(categories.length, (i) {
              final cat = categories[i];
              final value = catTotals[cat]!;
              final pct = (value / total * 100);
              return PieChartSectionData(
                color: _chartColors[i % _chartColors.length],
                value: value,
                title: '${pct.toStringAsFixed(0)}%',
                titleStyle: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
                radius: 50,
              );
            }),
            centerSpaceRadius: 50,
            sectionsSpace: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Expense> expenses) {
    final dailyTotals = <int, double>{};
    for (final e in expenses) {
      dailyTotals[e.date.day] =
          (dailyTotals[e.date.day] ?? 0) + e.amount;
    }

    final maxY = dailyTotals.values.isEmpty
        ? 100.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: const Color(0xFF2C2C2C),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF616161), fontSize: 10),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      'LKR ${value.toInt()}',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF616161), fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            barGroups: dailyTotals.entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: const Color(0xFF00C9A7),
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
      List<MapEntry<String, double>> sortedCats, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('By Category',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...sortedCats.asMap().entries.map((mapEntry) {
          final idx = mapEntry.key;
          final entry = mapEntry.value;
          final pct = entry.value / total;
          final color = _chartColors[idx % _chartColors.length];
          final icon = _categoryIcons[entry.key] ?? Icons.circle;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: const Color(0xFF2C2C2C),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('LKR ${formatCurrency(entry.value)}',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
