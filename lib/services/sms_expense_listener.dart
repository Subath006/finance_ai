import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/expense.dart';
import 'firestore_service.dart';
import 'receipt_scanner_service.dart';

/// Keywords that indicate a card/bank payment SMS
const _transactionKeywords = [
  'debited',
  'debit',
  'spent',
  'purchased',
  'purchase',
  'transaction',
  'payment',
  'withdrawn',
  'charged',
  'transferred',
  'paid',
  'deducted',
  'pos',
  'atm',
  'card ending',
  'card no',
  'credit card',
  'debit card',
  'visa',
  'mastercard',
];

/// Service that listens for incoming SMS and auto-detects card payments.
/// Runs in the foreground while the app is open.
class SmsExpenseListener {
  final Telephony _telephony = Telephony.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Tracks SMS IDs we've already processed to avoid duplicates
  final Set<String> _processedIds = {};

  /// Current user ID — must be set before starting
  String? _userId;

  /// Notifier for pending transaction count (UI can listen to this)
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  /// Whether the listener is currently active
  bool _isListening = false;
  bool get isListening => _isListening;

  /// Request SMS permissions and start listening
  Future<bool> startListening(String userId) async {
    _userId = userId;

    // Request SMS permission
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      debugPrint('SMS permission denied');
      return false;
    }

    // Start listening for incoming SMS
    _telephony.listenIncomingSms(
      onNewMessage: _onSmsReceived,
      listenInBackground: false, // foreground only
    );

    _isListening = true;
    debugPrint('SMS expense listener started for user: $userId');
    return true;
  }

  /// Stop listening
  void stopListening() {
    _isListening = false;
    _userId = null;
    debugPrint('SMS expense listener stopped');
  }

  /// Called when a new SMS is received
  void _onSmsReceived(SmsMessage message) {
    final body = message.body ?? '';
    final address = message.address ?? '';

    if (body.isEmpty) return;

    // Create a unique ID for deduplication
    final smsId = '${address}_${body.hashCode}_${DateTime.now().millisecondsSinceEpoch ~/ 10000}';
    if (_processedIds.contains(smsId)) return;

    debugPrint('SMS received from: $address');

    // Check if this looks like a transaction SMS
    if (_isTransactionSms(body)) {
      debugPrint('Transaction SMS detected! Processing...');
      _processedIds.add(smsId);
      _processTransactionSms(body);
    }
  }

  /// Check if SMS body contains transaction-related keywords
  bool _isTransactionSms(String body) {
    final lower = body.toLowerCase();
    return _transactionKeywords.any((keyword) => lower.contains(keyword));
  }

  /// Process a transaction SMS: parse with AI and save directly as an expense
  Future<void> _processTransactionSms(String smsBody) async {
    if (_userId == null) return;

    try {
      // Parse with AI (falls back to regex)
      final result =
          await ReceiptScannerService.parseTransactionSMS(smsBody);

      if (result == null) {
        debugPrint('Could not parse transaction from SMS');
        return;
      }

      // Create an Expense directly (skipping the approval step)
      final expense = Expense(
        userId: _userId!,
        amount: result.amount,
        category: result.category ?? 'Other',
        description: result.vendor ?? 'Auto-detected Payment',
        date: DateTime.now(),
      );

      // Save to Firestore
      await _firestoreService.addExpense(_userId!, expense);

      debugPrint(
          'Auto-saved expense: LKR ${result.amount} for ${result.vendor ?? "unknown"}');
    } catch (e) {
      debugPrint('Error processing transaction SMS: $e');
    }
  }

  /// Check if SMS permission is granted
  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Clean up
  void dispose() {
    stopListening();
    pendingCount.dispose();
  }
}
