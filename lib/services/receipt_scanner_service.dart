import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

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

  static GenerativeModel get _geminiModel {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite',
    );
    return _model!;
  }

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

  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  Future<ReceiptAnalysisResult> analyzeReceipt(File imageFile) async {
    final ocrText = await extractText(imageFile);

    if (ocrText.trim().isEmpty) {
      return ReceiptAnalysisResult(
        amount: null,
        vendor: null,
        rawText: '',
        usedAI: false,
      );
    }

    try {
      final result = await _analyzeTextWithAI(ocrText);
      if (result != null) return result;
    } catch (e) {
      debugPrint('Receipt AI analysis failed: $e');
    }

    return ReceiptAnalysisResult(
      amount: parseAmount(ocrText),
      vendor: parseVendorName(ocrText),
      date: null,
      category: null,
      rawText: ocrText,
      usedAI: false,
    );
  }

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
        '{"total_amount": <number_or_null>, "vendor": "<name_or_null>", "date": "<date_or_null>", "category": "<category>"}',
      ),
    ];

    final response = await _geminiModel
        .generateContent(prompt)
        .timeout(const Duration(seconds: 10));

    final text = response.text?.trim() ?? '';
    if (text.isEmpty) return null;

    return _parseAIResponse(text, ocrText);
  }

  ReceiptAnalysisResult? _parseAIResponse(String text, String ocrText) {
    try {
      String cleaned = text;
      if (cleaned.contains('```')) {
        cleaned = cleaned.replaceAll(
          RegExp(r'```json\s*', caseSensitive: false),
          '',
        );
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

      if (amount == null && vendor == null) return null;

      return ReceiptAnalysisResult(
        amount: amount,
        vendor: (vendor != null && vendor.toLowerCase() != 'null')
            ? vendor
            : null,
        date: (date != null && date.toLowerCase() != 'null') ? date : null,
        category: (category != null && category.toLowerCase() != 'null')
            ? category
            : null,
        rawText: ocrText,
        usedAI: true,
      );
    } catch (e) {
      debugPrint('Receipt AI JSON parse failed: $e — raw: $text');
      return null;
    }
  }

  double? parseAmount(String text) {
    final lines = text.split('\n');

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

  String? parseVendorName(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && trimmed.length > 2) {
        final letterCount = trimmed.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
        if (letterCount > trimmed.length * 0.3) {
          return trimmed;
        }
      }
    }
    return null;
  }

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

  static Future<TransactionParseResult?> parseTransactionSMS(
    String smsBody,
  ) async {
    try {
      final prompt = [
        Content.text(
          'You are a bank SMS parser. Analyze this SMS message and extract transaction details.\n'
          '1. amount - the transaction amount (number only, no currency symbols)\n'
          '2. vendor - merchant/store name if mentioned\n'
          '3. card_last4 - last 4 digits of card if mentioned\n'
          '4. category - one of: Food, Transport, Entertainment, Utilities, Shopping, Health, Education, Other\n\n'
          'SMS text:\n'
          '---\n'
          '$smsBody\n'
          '---\n\n'
          'Respond with ONLY valid JSON, no other text:\n'
          '{"amount": <number_or_null>, "vendor": "<name_or_null>", "card_last4": "<digits_or_null>", "category": "<category>"}',
        ),
      ];

      final response = await _geminiModel
          .generateContent(prompt)
          .timeout(const Duration(seconds: 10));

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) return null;

      return _parseSmsAIResponse(text, smsBody);
    } catch (e) {
      debugPrint('SMS AI parse failed: $e');
    }

    return _parseSmsFallback(smsBody);
  }

  static TransactionParseResult? _parseSmsAIResponse(
    String text,
    String smsBody,
  ) {
    try {
      String cleaned = text;
      if (cleaned.contains('```')) {
        cleaned = cleaned.replaceAll(
          RegExp(r'```json\s*', caseSensitive: false),
          '',
        );
        cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '');
        cleaned = cleaned.trim();
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      final amount = json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : null;
      if (amount == null || amount <= 0) return null;

      final vendor = json['vendor'] as String?;
      final cardLast4 = json['card_last4'] as String?;
      final category = json['category'] as String?;

      return TransactionParseResult(
        amount: amount,
        vendor: (vendor != null && vendor.toLowerCase() != 'null')
            ? vendor
            : null,
        cardLast4: (cardLast4 != null && cardLast4.toLowerCase() != 'null')
            ? cardLast4
            : null,
        category: (category != null && category.toLowerCase() != 'null')
            ? category
            : 'Other',
        rawSms: smsBody,
      );
    } catch (e) {
      debugPrint('SMS AI JSON parse failed: $e');
      return null;
    }
  }

  static TransactionParseResult? _parseSmsFallback(String smsBody) {
    final amountRegex = RegExp(
      r'(?:LKR|Rs\.?|USD|EUR)\s*([0-9,]+\.?\d*)',
      caseSensitive: false,
    );
    final match = amountRegex.firstMatch(smsBody);
    if (match == null) return null;

    final amountStr = match.group(1)?.replaceAll(',', '');
    final amount = double.tryParse(amountStr ?? '');
    if (amount == null || amount <= 0) return null;

    String? cardLast4;
    final cardRegex = RegExp(
      r'(?:ending|card|xx|xxxx|••••)\s*(\d{4})',
      caseSensitive: false,
    );
    final cardMatch = cardRegex.firstMatch(smsBody);
    if (cardMatch != null) {
      cardLast4 = cardMatch.group(1);
    }

    return TransactionParseResult(
      amount: amount,
      vendor: null,
      cardLast4: cardLast4,
      category: 'Other',
      rawSms: smsBody,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class TransactionParseResult {
  final double amount;
  final String? vendor;
  final String? cardLast4;
  final String? category;
  final String rawSms;

  const TransactionParseResult({
    required this.amount,
    this.vendor,
    this.cardLast4,
    this.category,
    required this.rawSms,
  });
}
