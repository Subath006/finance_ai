import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../utils/currency_formatter.dart';
import 'login_screen.dart';
import 'savings_goals_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final user = authService.currentUser;
    final email = user?.email ?? 'User';
    final userId = user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9A7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Email
              Text(
                email,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Member since ${_memberSince(user)}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 32),

              // Stats
              if (userId != null)
                StreamBuilder<List<Expense>>(
                  stream: firestoreService.getExpenses(userId),
                  builder: (context, snapshot) {
                    final expenses = snapshot.data ?? [];
                    final total = expenses.fold<double>(
                        0, (sum, e) => sum + e.amount);
                    final categories = expenses
                        .map((e) => e.category)
                        .toSet()
                        .length;

                    return Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Total Expenses',
                            expenses.length.toString(),
                            Icons.receipt_long_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'Total Spent',
                            'LKR ${formatCurrencyWhole(total)}',
                            Icons.account_balance_wallet_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'Categories',
                            categories.toString(),
                            Icons.category_rounded,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 32),

              // Menu Items
              _menuItem(
                icon: Icons.flag_rounded,
                label: 'Savings Goals',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SavingsGoalsScreen()),
                  );
                },
              ),
              _menuItem(
                icon: Icons.lock_rounded,
                label: 'Privacy & Security',
                onTap: () {},
              ),
              _menuItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {},
              ),
              _menuItem(
                icon: Icons.info_outline_rounded,
                label: 'About',
                trailing: Text(
                  'v1.0.0',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9E9E9E),
                    fontSize: 13,
                  ),
                ),
                onTap: () {},
              ),
              const SizedBox(height: 16),

              // Logout
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authService.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text('Logout',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: const Color(0xFFCF6679),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _memberSince(dynamic user) {
    if (user?.metadata?.creationTime != null) {
      final d = user!.metadata!.creationTime!;
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[d.month]} ${d.year}';
    }
    return 'recently';
  }

  static Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00C9A7), size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF9E9E9E),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF9E9E9E), size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                trailing ??
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF616161), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
