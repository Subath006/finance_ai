import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/pending_transaction.dart';
import 'firestore_service.dart';
import 'receipt_scanner_service.dart';

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

class SmsExpenseListener {
  final Telephony _telephony = Telephony.instance;
  final FirestoreService _firestoreService = FirestoreService();

  final Set<String> _processedIds = {};

  String? _userId;

  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  bool _isListening = false;
  bool get isListening => _isListening;

  Future<bool> startListening(String userId) async {
    _userId = userId;

    final status = await Permission.sms.request();
    if (!status.isGranted) {
      debugPrint('SMS permission denied');
      return false;
    }

    _telephony.listenIncomingSms(
      onNewMessage: _onSmsReceived,
      listenInBackground: false, // foreground only
    );

    _isListening = true;
    debugPrint('SMS expense listener started for user: $userId');
    return true;
  }

  void stopListening() {
    _isListening = false;
    _userId = null;
    debugPrint('SMS expense listener stopped');
  }

  void _onSmsReceived(SmsMessage message) {
    final body = message.body ?? '';
    final address = message.address ?? '';

    if (body.isEmpty) return;

    final smsId =
        '${address}_${body.hashCode}_${DateTime.now().millisecondsSinceEpoch ~/ 10000}';
    if (_processedIds.contains(smsId)) return;

    debugPrint('SMS received from: $address');

    if (_isTransactionSms(body)) {
      debugPrint('Transaction SMS detected! Processing...');
      _processedIds.add(smsId);
      _processTransactionSms(body);
    }
  }

  bool _isTransactionSms(String body) {
    final lower = body.toLowerCase();
    return _transactionKeywords.any((keyword) => lower.contains(keyword));
  }

  Future<void> _processTransactionSms(String smsBody) async {
    if (_userId == null) return;

    try {
      final result = await ReceiptScannerService.parseTransactionSMS(smsBody);

      if (result == null) {
        debugPrint('Could not parse transaction from SMS');
        return;
      }

      final pending = PendingTransaction(
        userId: _userId!,
        amount: result.amount,
        vendor: result.vendor,
        category: result.category ?? 'Other',
        cardLast4: result.cardLast4,
        rawSms: result.rawSms,
        detectedAt: DateTime.now(),
      );

      await _firestoreService.addPendingTransaction(_userId!, pending);
      pendingCount.value++;

      debugPrint(
        'Pending transaction saved: ${result.amount} at ${result.vendor ?? "unknown"}',
      );
    } catch (e) {
      debugPrint('Error processing transaction SMS: $e');
    }
  }

  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  void dispose() {
    stopListening();
    pendingCount.dispose();
  }
}
