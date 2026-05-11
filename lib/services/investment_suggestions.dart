import 'package:flutter/material.dart';

/// A single investment suggestion
class InvestmentSuggestion {
  final IconData icon;
  final String title;
  final String description;
  final String riskLevel; // 'Low', 'Medium', 'High'
  final Color riskColor;

  const InvestmentSuggestion({
    required this.icon,
    required this.title,
    required this.description,
    required this.riskLevel,
    required this.riskColor,
  });
}

/// A financial tip
class FinancialTip {
  final IconData icon;
  final String title;
  final String description;

  const FinancialTip({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Generates investment suggestions and tips based on monthly savings.
class InvestmentSuggestionsEngine {
  static const _green = Color(0xFF00C9A7);
  static const _yellow = Color(0xFFFFE66D);
  static const _red = Color(0xFFCF6679);

  /// Returns suggestions based on the savings (income - expenses) amount.
  static List<InvestmentSuggestion> getSuggestions(double savings) {
    if (savings < 0) {
      return _overspendingSuggestions;
    } else if (savings < 5000) {
      return _lowSavings;
    } else if (savings < 25000) {
      return _mediumSavings;
    } else if (savings < 100000) {
      return _highSavings;
    } else {
      return _premiumSavings;
    }
  }

  /// Returns general financial tips relevant to the savings level.
  static List<FinancialTip> getTips(double savings) {
    final tips = <FinancialTip>[
      const FinancialTip(
        icon: Icons.pie_chart_rounded,
        title: '50/30/20 Rule',
        description:
            'Allocate 50% of income to needs, 30% to wants, and 20% to savings & investments.',
      ),
      const FinancialTip(
        icon: Icons.shield_rounded,
        title: 'Emergency Fund First',
        description:
            'Build an emergency fund covering 3–6 months of expenses before investing.',
      ),
      const FinancialTip(
        icon: Icons.trending_up_rounded,
        title: 'Start Early, Stay Consistent',
        description:
            'Compound interest rewards early and regular investing — even small amounts grow over time.',
      ),
    ];

    if (savings < 0) {
      tips.insert(
        0,
        const FinancialTip(
          icon: Icons.warning_amber_rounded,
          title: 'Track Every Expense',
          description:
              'You are spending more than you earn. Review each category and cut unnecessary costs.',
        ),
      );
    }

    if (savings > 25000) {
      tips.add(
        const FinancialTip(
          icon: Icons.diversity_3_rounded,
          title: 'Diversify Your Portfolio',
          description:
              'Spread investments across multiple asset classes to reduce risk.',
        ),
      );
    }

    if (savings > 50000) {
      tips.add(
        const FinancialTip(
          icon: Icons.auto_graph_rounded,
          title: 'Consider Professional Advice',
          description:
              'With significant savings, a financial advisor can help optimize your returns.',
        ),
      );
    }

    return tips;
  }

  // ── Tier: Overspending ──────────────────────────────────

  static const _overspendingSuggestions = [
    InvestmentSuggestion(
      icon: Icons.savings_rounded,
      title: 'Build a Budget',
      description:
          'You\'re spending more than you earn. Create a strict monthly budget and stick to it.',
      riskLevel: 'Urgent',
      riskColor: _red,
    ),
    InvestmentSuggestion(
      icon: Icons.restaurant_rounded,
      title: 'Cut Discretionary Spending',
      description:
          'Review entertainment, dining out, and shopping. Reduce these by 20–30% this month.',
      riskLevel: 'Urgent',
      riskColor: _red,
    ),
    InvestmentSuggestion(
      icon: Icons.account_balance_rounded,
      title: 'Pay Off High-Interest Debt',
      description:
          'Focus on clearing credit cards and personal loans before saving.',
      riskLevel: 'Urgent',
      riskColor: _red,
    ),
  ];

  // ── Tier: LKR 0 – 5,000 ───────────────────────────────

  static const _lowSavings = [
    InvestmentSuggestion(
      icon: Icons.account_balance_rounded,
      title: 'High-Interest Savings Account',
      description:
          'Park your savings in a bank account offering the best interest rate. Safe and liquid.',
      riskLevel: 'Low',
      riskColor: _green,
    ),
    InvestmentSuggestion(
      icon: Icons.savings_rounded,
      title: 'Automated Savings',
      description:
          'Set up an automatic monthly transfer to a savings account — even LKR 1,000 adds up.',
      riskLevel: 'Low',
      riskColor: _green,
    ),
    InvestmentSuggestion(
      icon: Icons.shopping_cart_rounded,
      title: 'Reduce Small Recurring Costs',
      description:
          'Cancel unused subscriptions and switch to cheaper alternatives.',
      riskLevel: 'Low',
      riskColor: _green,
    ),
  ];

  // ── Tier: LKR 5,000 – 25,000 ──────────────────────────

  static const _mediumSavings = [
    InvestmentSuggestion(
      icon: Icons.lock_clock_rounded,
      title: 'Fixed Deposit',
      description:
          'Lock in funds for 6–12 months at a higher interest rate than regular savings.',
      riskLevel: 'Low',
      riskColor: _green,
    ),
    InvestmentSuggestion(
      icon: Icons.bar_chart_rounded,
      title: 'Unit Trust / Mutual Fund',
      description:
          'Invest in a diversified portfolio managed by professionals. Good entry point for beginners.',
      riskLevel: 'Medium',
      riskColor: _yellow,
    ),
    InvestmentSuggestion(
      icon: Icons.shield_rounded,
      title: 'Emergency Fund',
      description:
          'If you haven\'t yet, prioritize building 3 months of expenses as an emergency cushion.',
      riskLevel: 'Low',
      riskColor: _green,
    ),
  ];

  // ── Tier: LKR 25,000 – 100,000 ────────────────────────

  static const _highSavings = [
    InvestmentSuggestion(
      icon: Icons.account_balance_rounded,
      title: 'Government Bonds / Treasury Bills',
      description:
          'Invest in government securities for stable, guaranteed returns over 1–5 years.',
      riskLevel: 'Low',
      riskColor: _green,
    ),
    InvestmentSuggestion(
      icon: Icons.pie_chart_rounded,
      title: 'Diversified Mutual Fund',
      description:
          'Balanced funds that invest in both stocks and bonds for steady growth.',
      riskLevel: 'Medium',
      riskColor: _yellow,
    ),
    InvestmentSuggestion(
      icon: Icons.diamond_rounded,
      title: 'Gold Investment',
      description:
          'Buy gold coins or invest in gold-backed funds as a hedge against inflation.',
      riskLevel: 'Medium',
      riskColor: _yellow,
    ),
    InvestmentSuggestion(
      icon: Icons.health_and_safety_rounded,
      title: 'Insurance & Retirement',
      description:
          'Consider a life insurance policy or start a retirement savings plan.',
      riskLevel: 'Low',
      riskColor: _green,
    ),
  ];

  // ── Tier: LKR 100,000+ ────────────────────────────────

  static const _premiumSavings = [
    InvestmentSuggestion(
      icon: Icons.show_chart_rounded,
      title: 'Stock Market (CSE)',
      description:
          'Invest in blue-chip stocks on the Colombo Stock Exchange for long-term capital growth.',
      riskLevel: 'High',
      riskColor: _red,
    ),
    InvestmentSuggestion(
      icon: Icons.apartment_rounded,
      title: 'Real Estate',
      description:
          'Consider a down payment on property or invest in a real estate fund for passive income.',
      riskLevel: 'High',
      riskColor: _red,
    ),
    InvestmentSuggestion(
      icon: Icons.pie_chart_rounded,
      title: 'Diversified Portfolio',
      description:
          'Split across bonds (40%), equity funds (40%), and gold (20%) for balanced growth.',
      riskLevel: 'Medium',
      riskColor: _yellow,
    ),
    InvestmentSuggestion(
      icon: Icons.elderly_rounded,
      title: 'Retirement Planning',
      description:
          'Max out EPF/ETF contributions or open a voluntary pension fund for tax benefits.',
      riskLevel: 'Low',
      riskColor: _green,
    ),
    InvestmentSuggestion(
      icon: Icons.school_rounded,
      title: 'Invest in Education / Skills',
      description:
          'Professional certifications or courses can boost earning potential significantly.',
      riskLevel: 'Low',
      riskColor: _green,
    ),
  ];
}
