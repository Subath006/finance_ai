import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense.dart';
import '../models/savings_goal.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/currency_formatter.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});
  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final _fs = FirestoreService();
  final _auth = AuthService();

  final _icons = <String, IconData>{
    'savings': Icons.savings_rounded,
    'flight': Icons.flight_rounded,
    'home': Icons.home_rounded,
    'car': Icons.directions_car_rounded,
    'phone': Icons.phone_iphone_rounded,
    'school': Icons.school_rounded,
    'health': Icons.favorite_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'gift': Icons.card_giftcard_rounded,
    'other': Icons.star_rounded,
  };

  final _iconColors = <String, Color>{
    'savings': const Color(0xFF00C9A7),
    'flight': const Color(0xFF45B7D1),
    'home': const Color(0xFFFFE66D),
    'car': const Color(0xFF4ECDC4),
    'phone': const Color(0xFFF7AEF8),
    'school': const Color(0xFFDDA0DD),
    'health': const Color(0xFF95E77E),
    'shopping': const Color(0xFFFF6B6B),
    'gift': const Color(0xFFFFB74D),
    'other': const Color(0xFFB8B8B8),
  };

  void _showGoalDialog(String userId, {SavingsGoal? existing}) {
    final titleCtl = TextEditingController(text: existing?.title ?? '');
    final amountCtl = TextEditingController(
        text: existing != null ? formatCurrency(existing.targetAmount) : '');
    String selIcon = existing?.icon ?? 'savings';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF616161), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(existing != null ? 'Edit Goal' : 'New Savings Goal',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Set a target and start saving',
                  style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 13)),
              const SizedBox(height: 24),

              // Icon picker
              Text('Icon', style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _icons.entries.map((e) {
                    final isSel = e.key == selIcon;
                    final c = _iconColors[e.key] ?? Colors.grey;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setS(() => selIcon = e.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: isSel ? c.withValues(alpha: 0.2) : const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSel ? c : Colors.transparent, width: 1.5),
                          ),
                          child: Icon(e.value, color: isSel ? c : const Color(0xFF9E9E9E), size: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text('Goal Name', style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: titleCtl,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'e.g. New iPhone, Vacation',
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF616161)),
                  filled: true, fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Target amount
              Text('Target Amount', style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [CurrencyInputFormatter()],
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  prefixText: 'LKR ', prefixStyle: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 18),
                  hintText: '0.00', filled: true, fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 28),

              // Save
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleCtl.text.trim();
                    final amt = double.tryParse(stripCommas(amountCtl.text.trim()));
                    if (title.isEmpty || amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Fill in all fields', style: GoogleFonts.poppins()),
                        backgroundColor: const Color(0xFFCF6679),
                      ));
                      return;
                    }
                    Navigator.pop(ctx);
                    if (existing != null) {
                      await _fs.updateSavingsGoal(userId, existing.copyWith(title: title, targetAmount: amt, icon: selIcon));
                    } else {
                      await _fs.addSavingsGoal(userId, SavingsGoal(userId: userId, title: title, targetAmount: amt, icon: selIcon));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7), foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(existing != null ? 'Update Goal' : 'Create Goal',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  void _showAddMoneyDialog(String userId, SavingsGoal goal) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add to "${goal.title}"', style: GoogleFonts.poppins(color: Colors.white, fontSize: 17)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Remaining: LKR ${formatCurrency(goal.remaining)}',
              style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [CurrencyInputFormatter()],
            autofocus: true,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              prefixText: 'LKR ', prefixStyle: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 18),
              filled: true, fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)))),
          TextButton(
            onPressed: () async {
              final amt = double.tryParse(stripCommas(ctl.text.trim()));
              if (amt == null || amt <= 0) return;
              Navigator.pop(ctx);
              // Update savings goal
              await _fs.addGoalContribution(userId, goal.id!, amt);
              // Also record as an expense
              final expense = Expense(
                userId: userId,
                amount: amt,
                category: 'Savings',
                description: 'Savings: ${goal.title}',
                date: DateTime.now(),
              );
              await _fs.addExpense(userId, expense);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('LKR ${formatCurrency(amt)} added & recorded as expense', style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xFF00C9A7),
                ));
              }
            },
            child: Text('Add', style: GoogleFonts.poppins(color: const Color(0xFF00C9A7))),
          ),
        ],
      ),
    );
  }

  void _deleteGoal(String userId, String goalId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Goal', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('This will permanently remove this goal.', style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)))),
          TextButton(onPressed: () async { Navigator.pop(ctx); await _fs.deleteSavingsGoal(userId, goalId); },
              child: Text('Delete', style: GoogleFonts.poppins(color: const Color(0xFFCF6679)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Savings Goals', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF121212), elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<List<SavingsGoal>>(
        stream: _fs.streamSavingsGoals(userId),
        builder: (context, snap) {
          final goals = snap.data ?? [];

          if (goals.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 80, height: 80,
                  decoration: BoxDecoration(color: const Color(0xFF00C9A7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
                  child: const Icon(Icons.flag_rounded, color: Color(0xFF00C9A7), size: 36)),
              const SizedBox(height: 20),
              Text('No savings goals yet', style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text('Start saving towards\nsomething you love', textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: const Color(0xFF616161), fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showGoalDialog(userId),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('Create Goal', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ]));
          }

          // Summary
          final totalTarget = goals.fold<double>(0, (s, g) => s + g.targetAmount);
          final totalSaved = goals.fold<double>(0, (s, g) => s + g.savedAmount);
          final completedCount = goals.where((g) => g.isCompleted).length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Total Progress', style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('LKR ${formatCurrencyWhole(totalSaved)}',
                          style: GoogleFonts.poppins(color: const Color(0xFF00C9A7), fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('of LKR ${formatCurrencyWhole(totalTarget)}',
                          style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 12)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF00C9A7).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: Text('$completedCount/${goals.length} done',
                          style: GoogleFonts.poppins(color: const Color(0xFF00C9A7), fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalTarget > 0 ? (totalSaved / totalTarget).clamp(0, 1) : 0,
                      minHeight: 6, backgroundColor: const Color(0xFF2C2C2C),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF00C9A7)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              Text('Your Goals', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              // Goal cards
              ...goals.map((goal) {
                final ic = _icons[goal.icon] ?? Icons.savings_rounded;
                final clr = _iconColors[goal.icon] ?? const Color(0xFF00C9A7);
                final pct = goal.progress;

                Color barColor;
                if (goal.isCompleted) {
                  barColor = const Color(0xFF00C9A7);
                } else if (pct >= 0.6) {
                  barColor = const Color(0xFFFFE66D);
                } else {
                  barColor = const Color(0xFF45B7D1);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: Key(goal.id ?? goal.title),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: const Color(0xFFCF6679).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete_rounded, color: Color(0xFFCF6679)),
                    ),
                    confirmDismiss: (_) async { if (goal.id != null) _deleteGoal(userId, goal.id!); return false; },
                    child: GestureDetector(
                      onTap: () => _showGoalDialog(userId, existing: goal),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16),
                          border: goal.isCompleted ? Border.all(color: const Color(0xFF00C9A7).withValues(alpha: 0.4)) : null,
                        ),
                        child: Column(children: [
                          Row(children: [
                            Container(width: 48, height: 48,
                                decoration: BoxDecoration(color: clr.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                                child: Icon(ic, color: clr, size: 24)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(goal.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                                if (goal.isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFF00C9A7).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Text('Done!', style: GoogleFonts.poppins(color: const Color(0xFF00C9A7), fontSize: 10, fontWeight: FontWeight.w600)),
                                  ),
                              ]),
                              const SizedBox(height: 2),
                              Text('LKR ${formatCurrency(goal.savedAmount)} / ${formatCurrency(goal.targetAmount)}',
                                  style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 12)),
                            ])),
                            const SizedBox(width: 10),
                            Text('${(pct * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(color: barColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: pct, minHeight: 6,
                                backgroundColor: const Color(0xFF2C2C2C), valueColor: AlwaysStoppedAnimation(barColor)),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: Text('LKR ${formatCurrency(goal.remaining)} remaining',
                                style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 11))),
                            if (!goal.isCompleted)
                              GestureDetector(
                                onTap: () => _showAddMoneyDialog(userId, goal),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: const Color(0xFF00C9A7).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.add_rounded, color: Color(0xFF00C9A7), size: 16),
                                    const SizedBox(width: 4),
                                    Text('Add Money', style: GoogleFonts.poppins(color: const Color(0xFF00C9A7), fontSize: 12, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalDialog(userId),
        backgroundColor: const Color(0xFF00C9A7), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }
}
