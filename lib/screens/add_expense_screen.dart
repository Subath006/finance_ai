import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/categorization_engine.dart';
import '../utils/currency_formatter.dart';

class AddExpenseScreen extends StatefulWidget {
  final double? prefillAmount;
  final String? prefillDescription;

  const AddExpenseScreen({
    super.key,
    this.prefillAmount,
    this.prefillDescription,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  String _selectedCategory = 'Other';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _autoCategorized = false;
  bool _isCategorizing = false;
  double _confidence = 0.0;
  bool _isAI = false;
  Timer? _debounce;

  final List<String> _categories = CategorizationEngine.categories;

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

  @override
  void initState() {
    super.initState();
    if (widget.prefillAmount != null) {
      _amountController.text = widget.prefillAmount!.toStringAsFixed(2);
    }
    if (widget.prefillDescription != null) {
      _descriptionController.text = widget.prefillDescription!;
      _triggerAICategorization();
    }
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    // Debounce AI calls — wait 600ms after user stops typing
    _debounce?.cancel();
    final text = _descriptionController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _selectedCategory = 'Other';
        _autoCategorized = false;
        _isCategorizing = false;
        _confidence = 0.0;
        _isAI = false;
      });
      return;
    }

    setState(() => _isCategorizing = true);

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _triggerAICategorization();
    });
  }

  Future<void> _triggerAICategorization() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) return;

    if (!mounted) return;
    setState(() => _isCategorizing = true);

    try {
      final result = await CategorizationEngine.categorizeWithAI(text);
      if (!mounted) return;

      setState(() {
        _selectedCategory = result.category;
        _confidence = result.confidence;
        _isAI = result.isAI;
        _autoCategorized = result.category != 'Other';
        _isCategorizing = false;
      });
    } catch (_) {
      // Fallback to rule-based if anything goes wrong
      if (!mounted) return;
      final fallback = CategorizationEngine.categorize(text);
      setState(() {
        _selectedCategory = fallback;
        _confidence = fallback == 'Other' ? 0.3 : 0.6;
        _isAI = false;
        _autoCategorized = fallback != 'Other';
        _isCategorizing = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00C9A7),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF121212)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final expense = Expense(
        userId: user.uid,
        amount: double.parse(stripCommas(_amountController.text)),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
      );

      await _firestoreService.addExpense(user.uid, expense);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
            backgroundColor: const Color(0xFFCF6679),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Add Expense',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount
              Text('Amount',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF9E9E9E), fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [CurrencyInputFormatter()],
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: 'LKR ',
                  prefixStyle: GoogleFonts.poppins(
                      color: const Color(0xFF00C9A7),
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                  hintText: '0.00',
                  hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF616161)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: Color(0xFF00C9A7), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter an amount';
                  final raw = stripCommas(val);
                  if (double.tryParse(raw) == null) {
                    return 'Enter a valid number';
                  }
                  if (double.parse(raw) <= 0) {
                    return 'Amount must be positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Description
              Text('Description',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF9E9E9E), fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Uber ride to office',
                  hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF616161)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFF00C9A7), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter a description';
                  }
                  return null;
                },
              ),

              // AI categorization status
              if (_isCategorizing) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: const Color(0xFF845EF7),
                        backgroundColor: const Color(0xFF845EF7).withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI is categorizing...',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF845EF7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (_autoCategorized && !_isCategorizing) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isAI
                        ? const Color(0xFF845EF7).withValues(alpha: 0.1)
                        : const Color(0xFF00C9A7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAI ? Icons.auto_awesome : Icons.bolt_rounded,
                        size: 14,
                        color: _isAI
                            ? const Color(0xFF845EF7)
                            : const Color(0xFF00C9A7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isAI
                            ? 'AI categorized as "$_selectedCategory" (${(_confidence * 100).toInt()}%)'
                            : 'Auto-categorized as "$_selectedCategory"',
                        style: GoogleFonts.poppins(
                          color: _isAI
                              ? const Color(0xFF845EF7)
                              : const Color(0xFF00C9A7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Category
              Text('Category',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF9E9E9E), fontSize: 13)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat;
                      _autoCategorized = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00C9A7)
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _categoryIcons[cat] ?? Icons.circle,
                            size: 16,
                            color:
                                isSelected ? Colors.white : const Color(0xFF9E9E9E),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: GoogleFonts.poppins(
                              color:
                                  isSelected ? Colors.white : const Color(0xFF9E9E9E),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Date
              Text('Date',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF9E9E9E), fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: Color(0xFF9E9E9E), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMM d, y').format(_selectedDate),
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Save Expense',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
}
