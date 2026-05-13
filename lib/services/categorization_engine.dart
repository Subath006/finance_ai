import 'dart:async';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

class CategorizationResult {
  final String category;
  final double confidence;
  final bool isAI;

  const CategorizationResult({
    required this.category,
    required this.confidence,
    required this.isAI,
  });
}

class CategorizationEngine {
  static GenerativeModel? _model;

  static GenerativeModel get _geminiModel {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite',
      systemInstruction: Content.system(
        'You are an expense categorization AI. '
        'Given an expense description, categorize it into EXACTLY one of these categories: '
        'Food, Transport, Entertainment, Utilities, Shopping, Health, Education, Other. '
        'Respond ONLY with valid JSON in this exact format: '
        '{"category": "<category_name>", "confidence": <0.0_to_1.0>}. '
        'The confidence should reflect how certain you are about the classification. '
        'Do not include any other text, explanation, or markdown formatting.',
      ),
    );
    return _model!;
  }

  static Future<CategorizationResult> categorizeWithAI(String description) async {
    if (description.trim().isEmpty) {
      return const CategorizationResult(
        category: 'Other',
        confidence: 1.0,
        isAI: false,
      );
    }

    try {
      final prompt = [
        Content.text('Categorize this expense: "$description"'),
      ];

      final response = await _geminiModel
          .generateContent(prompt)
          .timeout(const Duration(seconds: 8));

      final text = response.text?.trim() ?? '';

      final result = _parseAIResponse(text);
      if (result != null) {
        return result;
      }

      final extracted = _extractCategoryFromText(text);
      if (extracted != null) {
        return CategorizationResult(
          category: extracted,
          confidence: 0.7,
          isAI: true,
        );
      }
    } catch (_) {
    }

    final fallbackCategory = categorize(description);
    return CategorizationResult(
      category: fallbackCategory,
      confidence: fallbackCategory == 'Other' ? 0.3 : 0.6,
      isAI: false,
    );
  }

  static CategorizationResult? _parseAIResponse(String text) {
    try {
      // Strip markdown code fences if present
      String cleaned = text;
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '');
        cleaned = cleaned.replaceAll(RegExp(r'\n?```$'), '');
        cleaned = cleaned.trim();
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final category = json['category'] as String?;
      final confidence = (json['confidence'] as num?)?.toDouble();

      if (category == null) return null;

      final validCategory = _matchValidCategory(category);
      if (validCategory == null) return null;

      return CategorizationResult(
        category: validCategory,
        confidence: (confidence ?? 0.8).clamp(0.0, 1.0),
        isAI: true,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _matchValidCategory(String input) {
    final lower = input.toLowerCase().trim();
    for (final cat in categories) {
      if (cat.toLowerCase() == lower) return cat;
    }
    return null;
  }

  static String? _extractCategoryFromText(String text) {
    final lower = text.toLowerCase();
    for (final cat in categories) {
      if (lower.contains(cat.toLowerCase()) && cat != 'Other') {
        return cat;
      }
    }
    return null;
  }


  static const Map<String, String> _keywordCategoryMap = {
    'restaurant': 'Food',
    'dinner': 'Food',
    'lunch': 'Food',
    'breakfast': 'Food',
    'cafe': 'Food',
    'coffee': 'Food',
    'pizza': 'Food',
    'burger': 'Food',
    'grocery': 'Food',
    'supermarket': 'Food',
    'food': 'Food',
    'eat': 'Food',
    'meal': 'Food',
    'snack': 'Food',
    'bakery': 'Food',
    'takeout': 'Food',
    'takeaway': 'Food',
    'delivery': 'Food',

    'uber': 'Transport',
    'taxi': 'Transport',
    'bus': 'Transport',
    'train': 'Transport',
    'fuel': 'Transport',
    'petrol': 'Transport',
    'gas': 'Transport',
    'parking': 'Transport',
    'toll': 'Transport',
    'ride': 'Transport',
    'flight': 'Transport',
    'airline': 'Transport',
    'car': 'Transport',
    'metro': 'Transport',
    'transport': 'Transport',
    'commute': 'Transport',

    'movie': 'Entertainment',
    'cinema': 'Entertainment',
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'game': 'Entertainment',
    'concert': 'Entertainment',
    'theater': 'Entertainment',
    'theatre': 'Entertainment',
    'music': 'Entertainment',
    'streaming': 'Entertainment',
    'youtube': 'Entertainment',
    'subscription': 'Entertainment',
    'party': 'Entertainment',
    'fun': 'Entertainment',
    'entertainment': 'Entertainment',

    'electric': 'Utilities',
    'electricity': 'Utilities',
    'water': 'Utilities',
    'internet': 'Utilities',
    'wifi': 'Utilities',
    'phone': 'Utilities',
    'mobile': 'Utilities',
    'bill': 'Utilities',
    'utility': 'Utilities',
    'gas bill': 'Utilities',
    'heating': 'Utilities',
    'rent': 'Utilities',
    'insurance': 'Utilities',

    'clothes': 'Shopping',
    'shoes': 'Shopping',
    'amazon': 'Shopping',
    'shopping': 'Shopping',
    'mall': 'Shopping',
    'store': 'Shopping',
    'online': 'Shopping',
    'purchase': 'Shopping',
    'buy': 'Shopping',

    'doctor': 'Health',
    'hospital': 'Health',
    'medicine': 'Health',
    'pharmacy': 'Health',
    'gym': 'Health',
    'health': 'Health',
    'dental': 'Health',
    'medical': 'Health',
    'clinic': 'Health',

    'book': 'Education',
    'course': 'Education',
    'tuition': 'Education',
    'school': 'Education',
    'university': 'Education',
    'study': 'Education',
    'education': 'Education',
    'training': 'Education',
    'tutorial': 'Education',
  };

  static String categorize(String description) {
    if (description.trim().isEmpty) return 'Other';

    final lowerDescription = description.toLowerCase();

    for (final entry in _keywordCategoryMap.entries) {
      if (lowerDescription.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Other';
  }

  static List<String> get categories => [
        'Food',
        'Transport',
        'Entertainment',
        'Utilities',
        'Shopping',
        'Health',
        'Education',
        'Other',
      ];
}
