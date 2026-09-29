import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_flutter/models/transaction_model.dart';
import 'package:test_flutter/services/transaction_service.dart';
import 'package:test_flutter/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    NotificationService.resetForTesting();
    await TransactionService.clearTransactions();
  });

  group('NotificationService - Auto Detect & Anti Duplication', () {
    test('Simulate notification creates a PendingTransaction', () async {
      final pending = await NotificationService.simulateNotification(
        source: 'BCA',
        title: 'BCA Mobile',
        text: 'Transfer masuk Rp500.000 dari BUDI UTOMO',
        timestamp: DateTime(2026, 9, 29, 14, 0).millisecondsSinceEpoch,
      );

      expect(pending, isNotNull);
      expect(pending!.source, 'BCA');
      expect(pending.amount, 500000.0);
      expect(pending.isIncome, isTrue);
      expect(NotificationService.pendingTransactions.length, 1);
      expect(NotificationService.pendingCountNotifier.value, 1);

      // Existing transactions should NOT be modified yet!
      expect(TransactionService.transactions.isEmpty, isTrue);
    });

    test('Duplicate notification with identical fingerprint is rejected', () async {
      final fixedTime = DateTime(2026, 9, 29, 14, 0).millisecondsSinceEpoch;

      final first = await NotificationService.simulateNotification(
        source: 'BCA',
        title: 'BCA Mobile',
        text: 'Transfer masuk Rp500.000 dari BUDI UTOMO',
        timestamp: fixedTime,
      );
      expect(first, isNotNull);
      expect(NotificationService.pendingTransactions.length, 1);

      // Same notification arriving again (duplicate)
      final second = await NotificationService.simulateNotification(
        source: 'BCA',
        title: 'BCA Mobile',
        text: 'Transfer masuk Rp500.000 dari BUDI UTOMO',
        timestamp: fixedTime + 3000, // 3 seconds later
      );

      expect(second, isNull);
      expect(NotificationService.pendingTransactions.length, 1);
    });

    test('Confirm / Save pending transaction adds to main transactions and marks fingerprint', () async {
      final pending = await NotificationService.simulateNotification(
        source: 'GoPay',
        title: 'GoPay QRIS',
        text: 'Pembayaran QRIS Rp25.000 ke Kopi Kenangan berhasil',
        timestamp: DateTime(2026, 9, 29, 15, 30).millisecondsSinceEpoch,
      );

      expect(pending, isNotNull);
      expect(NotificationService.pendingTransactions.length, 1);
      expect(TransactionService.transactions.isEmpty, isTrue);

      // User confirms
      await NotificationService.confirmPendingTransaction(pending!);

      // Now pending is empty
      expect(NotificationService.pendingTransactions.isEmpty, isTrue);
      expect(NotificationService.pendingCountNotifier.value, 0);

      // Transaction is added to main transactions
      expect(TransactionService.transactions.length, 1);
      expect(TransactionService.transactions.first.amount, 25000.0);
      expect(TransactionService.transactions.first.isIncome, isFalse);

      // Re-receiving same notification after being confirmed is rejected
      final duplicate = await NotificationService.simulateNotification(
        source: 'GoPay',
        title: 'GoPay QRIS',
        text: 'Pembayaran QRIS Rp25.000 ke Kopi Kenangan berhasil',
        timestamp: DateTime(2026, 9, 29, 15, 30).millisecondsSinceEpoch,
      );
      expect(duplicate, isNull);
    });

    test('Ignore pending transaction does not add to main transactions', () async {
      final pending = await NotificationService.simulateNotification(
        source: 'DANA',
        title: 'DANA Promo',
        text: 'Cashback Rp 5.000 telah ditambahkan',
        timestamp: DateTime(2026, 9, 29, 12, 0).millisecondsSinceEpoch,
      );

      expect(pending, isNotNull);
      expect(NotificationService.pendingTransactions.length, 1);

      // User ignores
      await NotificationService.ignorePendingTransaction(pending!);

      expect(NotificationService.pendingTransactions.isEmpty, isTrue);
      expect(TransactionService.transactions.isEmpty, isTrue);

      // Fingerprint is still marked so it won't pop up again
      final retest = await NotificationService.simulateNotification(
        source: 'DANA',
        title: 'DANA Promo',
        text: 'Cashback Rp 5.000 telah ditambahkan',
        timestamp: DateTime(2026, 9, 29, 12, 0).millisecondsSinceEpoch,
      );
      expect(retest, isNull);
    });

    test('Existing transactions are preserved and not duplicated', () async {
      // Add existing transaction
      final existing = TransactionModel(
        id: 'existing_123',
        title: 'Gaji Bulanan',
        category: 'Pemasukan',
        amount: 10000000.0,
        isIncome: true,
        date: DateTime(2026, 9, 25),
      );
      await TransactionService.addTransaction(existing);
      expect(TransactionService.transactions.length, 1);

      // Detect new notification
      final pending = await NotificationService.simulateNotification(
        source: 'Mandiri',
        title: 'Debit Rekening',
        text: 'Debit Rp 1.500.000 untuk tagihan PLN',
      );
      expect(pending, isNotNull);

      // Existing transaction should still be there unchanged
      expect(TransactionService.transactions.length, 1);
      expect(TransactionService.transactions.first.id, 'existing_123');

      // Confirm new transaction
      await NotificationService.confirmPendingTransaction(pending!);

      // Now we have 2 transactions, existing is preserved
      expect(TransactionService.transactions.length, 2);
      expect(TransactionService.transactions.any((t) => t.id == 'existing_123'), isTrue);
    });
  });
}
