import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Result from AI-powered receipt analysis.
class ReceiptAnalysisResult {
  final double? amount;
  final String? vendor;
  final String? date;
  final String? category;
  final String rawText;
  final bool usedAI;

  const ReceiptAnalysisResult({
    this.amount,
    this.vendor,
    this.date,
    this.category,
    required this.rawText,
    required this.usedAI,
  });
}

class ReceiptScannerService {
  final _textRecognizer = TextRecognizer();
  final _imagePicker = ImagePicker();
  static GenerativeModel? _model;

  /// Lazily initialize the Gemini model for text-based receipt analysis
  static GenerativeModel get _geminiModel {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite',
    );
    return _model!;
  }

  /// Pick an image from camera or gallery
  Future<File?> pickImage({required bool fromCamera}) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  /// Extract text from an image file using ML Kit
  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  // ─── AI-Powered Receipt Analysis ──────────────────────────────────

  /// Analyze a receipt: OCR first, then send text to Gemini for smart parsing.
  /// Falls back to regex if AI fails.
  Future<ReceiptAnalysisResult> analyzeReceipt(File imageFile) async {
    // Step 1: Extract text via ML Kit OCR
    final ocrText = await extractText(imageFile);

    if (ocrText.trim().isEmpty) {
      return ReceiptAnalysisResult(
        amount: null,
        vendor: null,
        rawText: '',
        usedAI: false,
      );
    }

    // Step 2: Send OCR text to Gemini for intelligent parsing
    try {
      final result = await _analyzeTextWithAI(ocrText);
      if (result != null) return result;
    } catch (e) {
      debugPrint('Receipt AI analysis failed: $e');
    }

    // Step 3: Fallback to regex parsing
    return ReceiptAnalysisResult(
      amount: parseAmount(ocrText),
      vendor: parseVendorName(ocrText),
      date: null,
      category: null,
      rawText: ocrText,
      usedAI: false,
    );
  }

  /// Send OCR-extracted text to Gemini for intelligent receipt parsing
  Future<ReceiptAnalysisResult?> _analyzeTextWithAI(String ocrText) async {
    final prompt = [
      Content.text(
        'You are a receipt analysis AI. Analyze this OCR-extracted receipt text and extract:\n'
        '1. total_amount - the final total paid (number only, no currency symbols)\n'
        '2. vendor - the store/business name\n'
        '3. date - transaction date as YYYY-MM-DD if found\n'
        '4. category - one of: Food, Transport, Entertainment, Utilities, Shopping, Health, Education, Other\n\n'
        'Receipt text:\n'
        '---\n'
        '$ocrText\n'
        '---\n\n'
        'Respond with ONLY valid JSON, no other text:\n'
        '{"total_amount": <number_or_null>, "vendor": "<name_or_null>", "date": "<date_or_null>", "category": "<category>"}'
      ),
    ];

    final response = await _geminiModel
        .generateContent(prompt)
        .timeout(const Duration(seconds: 10));

    final text = response.text?.trim() ?? '';
    if (text.isEmpty) return null;

    return _parseAIResponse(text, ocrText);
  }

  /// Parse the JSON response from Gemini
  ReceiptAnalysisResult? _parseAIResponse(String text, String ocrText) {
    try {
      String cleaned = text;
      // Strip markdown code fences if present
      if (cleaned.contains('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'```json\s*', caseSensitive: false), '');
        cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '');
        cleaned = cleaned.trim();
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      final amount = json['total_amount'] != null
          ? (json['total_amount'] as num).toDouble()
          : null;
      final vendor = json['vendor'] as String?;
      final date = json['date'] as String?;
      final category = json['category'] as String?;

      // Validate we got at least something useful
      if (amount == null && vendor == null) return null;

      return ReceiptAnalysisResult(
        amount: amount,
        vendor: (vendor != null && vendor.toLowerCase() != 'null') ? vendor : null,
        date: (date != null && date.toLowerCase() != 'null') ? date : null,
        category: (category != null && category.toLowerCase() != 'null') ? category : null,
        rawText: ocrText,
        usedAI: true,
      );
    } catch (e) {
      debugPrint('Receipt AI JSON parse failed: $e — raw: $text');
      return null;
    }
  }

  // ─── Regex Fallback Methods ────────────────────────────────────────

  /// Parse extracted text to find amount using keyword + regex matching
  double? parseAmount(String text) {
    final lines = text.split('\n');

    // First pass: look for lines with total-related keywords
    for (final line in lines.reversed) {
      final lower = line.toLowerCase();
      if (lower.contains('total') ||
          lower.contains('amount') ||
          lower.contains('net') ||
          lower.contains('due') ||
          lower.contains('payable')) {
        final amount = _extractNumber(line);
        if (amount != null && amount > 0) return amount;
      }
    }

    // Second pass: find the largest number (likely the total)
    double? largest;
    for (final line in lines) {
      final amount = _extractNumber(line);
      if (amount != null && amount > 0) {
        if (largest == null || amount > largest) {
          largest = amount;
        }
      }
    }

    return largest;
  }

  /// Parse vendor/store name (usually first non-empty line with letters)
  String? parseVendorName(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && trimmed.length > 2) {
        final letterCount =
            trimmed.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
        if (letterCount > trimmed.length * 0.3) {
          return trimmed;
        }
      }
    }
    return null;
  }

  /// Extract a number from a string
  double? _extractNumber(String text) {
    final regex = RegExp(r'[\d,]+\.?\d*');
    final matches = regex.allMatches(text);

    double? largest;
    for (final match in matches) {
      final numStr = match.group(0)!.replaceAll(',', '');
      final value = double.tryParse(numStr);
      if (value != null && value > 0) {
        if (largest == null || value > largest) {
          largest = value;
        }
      }
    }
    return largest;
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
