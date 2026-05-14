import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/categorization_engine.dart';
import '../utils/currency_formatter.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({
    super.key,
    required this.expense,
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool _isRecategorizing = false;
  bool _aiRecategorized = false;
  double _confidence = 0.0;

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
    _amountController = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.expense.description,
    );
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _recategorizeWithAI() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isRecategorizing = true);

    try {
      final result = await CategorizationEngine.categorizeWithAI(text);
      if (!mounted) return;

      setState(() {
        _selectedCategory = result.category;
        _confidence = result.confidence;
        _aiRecategorized = true;
        _isRecategorizing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isAI
                  ? 'AI suggests: ${result.category} (${(result.confidence * 100).toInt()}% confident)'
                  : 'Categorized as: ${result.category} (rule-based)',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: result.isAI
                ? const Color(0xFF845EF7)
                : const Color(0xFF00C9A7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRecategorizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not categorize', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFCF6679),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              backgroundColor: Color(0xFF121212),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final updated = widget.expense.copyWith(
        amount: double.parse(stripCommas(_amountController.text)),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
      );

      await _firestoreService.updateExpense(user.uid, updated);

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
        title: Text(
          'Edit Expense',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
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
              Text(
                'Amount',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [CurrencyInputFormatter()],
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: 'LKR ',
                  prefixStyle: GoogleFonts.poppins(
                    color: const Color(0xFF00C9A7),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF00C9A7),
                      width: 1.5,
                    ),
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
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Uber ride to office',
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF616161),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF00C9A7),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter a description';
                  }
                  return null;
                },
              ),

              if (_aiRecategorized) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF845EF7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Color(0xFF845EF7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI re-categorized as "$_selectedCategory" (${(_confidence * 100).toInt()}%)',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF845EF7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: _isRecategorizing ? null : _recategorizeWithAI,
                  icon: _isRecategorizing
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: const Color(0xFF845EF7),
                            backgroundColor: const Color(
                              0xFF845EF7,
                            ).withValues(alpha: 0.2),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    _isRecategorizing
                        ? 'Categorizing...'
                        : 'Re-categorize with AI',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF845EF7),
                    side: BorderSide(
                      color: const Color(0xFF845EF7).withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Category',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat;
                      _aiRecategorized = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF9E9E9E),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF9E9E9E),
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

              Text(
                'Date',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF9E9E9E),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMM d, y').format(_selectedDate),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateExpense,
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
                          'Update Expense',
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
