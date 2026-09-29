import 'package:flutter_test/flutter_test.dart';
import 'package:test_flutter/services/notification_parser.dart';

void main() {
  group('NotificationParser - Nominal Parsing', () {
    test('Parse format Rp25.000', () {
      final amount = NotificationParser.extractAmount('Pembayaran Rp25.000 berhasil');
      expect(amount, 25000.0);
    });

    test('Parse format Rp 25.000', () {
      final amount = NotificationParser.extractAmount('Pembayaran Rp 25.000 berhasil');
      expect(amount, 25000.0);
    });

    test('Parse format Rp25,000', () {
      final amount = NotificationParser.extractAmount('Pembayaran Rp25,000 berhasil');
      expect(amount, 25000.0);
    });

    test('Parse format Rp 25,000', () {
      final amount = NotificationParser.extractAmount('Pembayaran Rp 25,000 berhasil');
      expect(amount, 25000.0);
    });

    test('Parse format 25.000', () {
      final amount = NotificationParser.extractAmount('Total pembayaran 25.000 berhasil');
      expect(amount, 25000.0);
    });

    test('Parse format 25,000', () {
      final amount = NotificationParser.extractAmount('Total pembayaran 25,000 berhasil');
      expect(amount, 25000.0);
    });

    test('Parse format Rp1.500.000 (tidak menjadi 1.500)', () {
      final amount = NotificationParser.extractAmount('Transfer keluar Rp1.500.000 berhasil');
      expect(amount, 1500000.0);
      expect(amount, isNot(1500.0));
    });

    test('Parse format Rp 1.500.000,00', () {
      final amount = NotificationParser.extractAmount('Debit rekening Rp 1.500.000,00 sukses');
      expect(amount, 1500000.0);
    });
  });

  group('NotificationParser - Income vs Expense', () {
    test('Detect income from "transfer masuk"', () {
      final parsed = NotificationParser.parse(
        packageName: 'com.bca',
        title: 'BCA Mobile',
        text: 'Transfer masuk Rp500.000 dari Ahmad',
      );
      expect(parsed, isNotNull);
      expect(parsed!.isIncome, isTrue);
      expect(parsed.amount, 500000.0);
      expect(parsed.source, 'BCA');
    });

    test('Detect income from "dana masuk"', () {
      final parsed = NotificationParser.parse(
        packageName: 'id.dana',
        title: 'DANA',
        text: 'Dana masuk sebesar Rp 100.000 berhasil',
      );
      expect(parsed, isNotNull);
      expect(parsed!.isIncome, isTrue);
      expect(parsed.amount, 100000.0);
    });

    test('Detect expense from "pembayaran QRIS"', () {
      final parsed = NotificationParser.parse(
        packageName: 'com.gojek.app',
        title: 'GoPay',
        text: 'Pembayaran QRIS Rp25.000 berhasil',
      );
      expect(parsed, isNotNull);
      expect(parsed!.isIncome, isFalse);
      expect(parsed.amount, 25000.0);
      expect(parsed.source, 'GoPay');
    });

    test('Detect expense from "transfer ke"', () {
      final parsed = NotificationParser.parse(
        packageName: 'id.bmri.livin',
        title: 'Livin Mandiri',
        text: 'Transfer ke rekening 987654 sebesar Rp 250.000 berhasil',
      );
      expect(parsed, isNotNull);
      expect(parsed!.isIncome, isFalse);
      expect(parsed.amount, 250000.0);
      expect(parsed.source, 'Mandiri');
    });
  });

  group('NotificationParser - Sources & Categories', () {
    test('Detect all supported banking and e-wallet sources', () {
      expect(NotificationParser.detectSource(packageName: 'com.bca', title: '', text: ''), 'BCA');
      expect(NotificationParser.detectSource(packageName: 'com.bri.bmo', title: '', text: ''), 'BRI');
      expect(NotificationParser.detectSource(packageName: 'id.bmri.livin', title: '', text: ''), 'Mandiri');
      expect(NotificationParser.detectSource(packageName: 'id.dana', title: '', text: ''), 'DANA');
      expect(NotificationParser.detectSource(packageName: 'com.gojek.app', title: '', text: ''), 'GoPay');
      expect(NotificationParser.detectSource(packageName: 'ovo.id', title: '', text: ''), 'OVO');
      expect(NotificationParser.detectSource(packageName: 'com.shopee.id', title: '', text: ''), 'ShopeePay');
    });

    test('Detect category Makanan', () {
      final category = NotificationParser.detectCategory(
        combinedText: 'Pembayaran resto bakso sebesar Rp 50.000',
        isIncome: false,
      );
      expect(category, 'Makanan');
    });

    test('Detect category Transportasi', () {
      final category = NotificationParser.detectCategory(
        combinedText: 'Pembayaran bensin di SPBU Pertamina Rp 100.000',
        isIncome: false,
      );
      expect(category, 'Transportasi');
    });

    test('Detect category Belanja', () {
      final category = NotificationParser.detectCategory(
        combinedText: 'Pembayaran Shopee pesanan Rp 75.000 berhasil',
        isIncome: false,
      );
      expect(category, 'Belanja');
    });

    test('Detect category Hiburan', () {
      final category = NotificationParser.detectCategory(
        combinedText: 'Langganan Netflix Rp 54.000 berhasil didebit',
        isIncome: false,
      );
      expect(category, 'Hiburan');
    });
  });

  group('NotificationParser - Anti Duplication Fingerprint', () {
    test('Exact notification generates identical deterministic fingerprint', () {
      final fixedDate = DateTime(2026, 9, 29, 16, 30, 15);
      final fp1 = NotificationParser.generateFingerprint(
        source: 'BCA',
        amount: 500000.0,
        isIncome: true,
        date: fixedDate,
        title: 'Transfer Masuk',
        packageName: 'com.bca',
      );

      // Notification arrives 5 seconds later in same minute
      final secondDate = DateTime(2026, 9, 29, 16, 30, 20);
      final fp2 = NotificationParser.generateFingerprint(
        source: 'BCA',
        amount: 500000.0,
        isIncome: true,
        date: secondDate,
        title: 'Transfer Masuk',
        packageName: 'com.bca',
      );

      expect(fp1, equals(fp2));
    });

    test('Different amount produces different fingerprint', () {
      final fixedDate = DateTime(2026, 9, 29, 16, 30);
      final fp1 = NotificationParser.generateFingerprint(
        source: 'BCA',
        amount: 500000.0,
        isIncome: true,
        date: fixedDate,
        title: 'Transfer Masuk',
        packageName: 'com.bca',
      );

      final fp2 = NotificationParser.generateFingerprint(
        source: 'BCA',
        amount: 250000.0,
        isIncome: true,
        date: fixedDate,
        title: 'Transfer Masuk',
        packageName: 'com.bca',
      );

      expect(fp1, isNot(equals(fp2)));
    });
  });
}
