import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/receipt_scanner_service.dart';
import '../utils/currency_formatter.dart';
import 'add_expense_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _scannerService = ReceiptScannerService();
  File? _imageFile;
  ReceiptAnalysisResult? _result;
  bool _isProcessing = false;

  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  String _selectedCategory = 'Other';
  String? _detectedDate;

  final List<String> _categories = [
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
  void dispose() {
    _scannerService.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcess(bool fromCamera) async {
    setState(() => _isProcessing = true);

    try {
      final file = await _scannerService.pickImage(fromCamera: fromCamera);
      if (file == null) {
        setState(() => _isProcessing = false);
        return;
      }

      setState(() => _imageFile = file);

      final result = await _scannerService.analyzeReceipt(file);

      _amountController.text = result.amount != null
          ? formatCurrency(result.amount!)
          : '';
      _vendorController.text = result.vendor ?? '';
      _selectedCategory = result.category ?? 'Other';
      _detectedDate = result.date;

      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: const Color(0xFFCF6679),
          ),
        );
      }
    }
  }

  void _addAsExpense() {
    final amount = double.tryParse(stripCommas(_amountController.text.trim()));
    final vendor = _vendorController.text.trim();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          prefillAmount: amount,
          prefillDescription: vendor.isNotEmpty ? vendor : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'Scan Receipt',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imageFile == null && !_isProcessing) ...[
              Text(
                'Capture or select a receipt image to automatically extract expense details using AI.',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndProcess(true),
                  icon: const Icon(Icons.camera_alt_rounded, size: 22),
                  label: Text(
                    'Take Photo',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndProcess(false),
                  icon: const Icon(Icons.photo_library_rounded, size: 22),
                  label: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],

            if (_isProcessing) ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: Color(0xFF845EF7),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'AI is analyzing receipt...',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF845EF7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Extracting amount, vendor & category',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9E9E9E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_imageFile != null && !_isProcessing && _result != null) ...[
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _imageFile!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _result!.usedAI
                      ? const Color(0xFF845EF7).withValues(alpha: 0.1)
                      : const Color(0xFF00C9A7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _result!.usedAI
                          ? Icons.auto_awesome
                          : Icons.text_fields_rounded,
                      size: 14,
                      color: _result!.usedAI
                          ? const Color(0xFF845EF7)
                          : const Color(0xFF00C9A7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _result!.usedAI
                          ? 'Analyzed with AI'
                          : 'Extracted with OCR',
                      style: GoogleFonts.poppins(
                        color: _result!.usedAI
                            ? const Color(0xFF845EF7)
                            : const Color(0xFF00C9A7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Extracted Information',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE66D).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFFFFE66D),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Editable',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFFE66D),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _fieldLabel('Amount'),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [CurrencyInputFormatter()],
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: 'LKR ',
                  prefixStyle: GoogleFonts.poppins(
                    color: const Color(0xFF00C9A7),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '0.00',
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
                  suffixIcon: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF616161),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _fieldLabel('Vendor / Description'),
              const SizedBox(height: 8),
              TextField(
                controller: _vendorController,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'e.g. Keells Super',
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
                  suffixIcon: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF616161),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _fieldLabel('Category'),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00C9A7)
                              : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
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

              if (_detectedDate != null) ...[
                const SizedBox(height: 20),
                _fieldLabel('Date (detected)'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
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
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _detectedDate!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(
                  'Raw Extracted Text',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9E9E9E),
                    fontSize: 13,
                  ),
                ),
                collapsedIconColor: const Color(0xFF9E9E9E),
                iconColor: const Color(0xFF00C9A7),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _result!.rawText.isEmpty
                          ? 'No text extracted'
                          : _result!.rawText,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9E9E9E),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _addAsExpense,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: Text(
                    'Add as Expense',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _imageFile = null;
                      _result = null;
                      _amountController.clear();
                      _vendorController.clear();
                      _selectedCategory = 'Other';
                      _detectedDate = null;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: Text(
                    'Scan Another',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: const Color(0xFF9E9E9E),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
