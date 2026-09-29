import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_transaction.dart';
import '../services/transaction_service.dart';
import 'notification_parser.dart';

class NotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.myfinance.app/notification_listener');

  static const String _keyPending = 'pending_notification_transactions';
  static const String _keyFingerprints = 'processed_notification_fingerprints';
  static const String _keyAutoDetect = 'notification_auto_detect_enabled';
  static const String _keyConfirm = 'notification_confirm_required';
  static const String _keySources = 'notification_enabled_sources';

  static final List<PendingTransaction> pendingTransactions = [];
  static final Set<String> processedFingerprints = {};

  static bool isAutoDetectEnabled = true;
  static bool isConfirmRequired = true;
  static Set<String> enabledSources = {
    'BCA',
    'BRI',
    'Mandiri',
    'DANA',
    'GoPay',
    'OVO',
    'ShopeePay',
  };

  static final ValueNotifier<int> pendingCountNotifier =
      ValueNotifier<int>(0);

  static bool _isInitialized = false;

  /// Initialize service, load stored settings and pending transactions
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadSettings();
    await _loadFingerprints();
    await _loadPending();

    // Setup method channel listener for real-time notifications on Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onNotificationReceived') {
          final Map<dynamic, dynamic>? args = call.arguments;
          if (args != null) {
            final map = Map<String, dynamic>.from(args);
            await processRawNotification(
              packageName: map['packageName']?.toString() ?? '',
              title: map['title']?.toString() ?? '',
              text: map['text']?.toString() ?? '',
              timestamp: map['timestamp'] as int?,
            );
          }
        }
      });

      // Synchronize any notifications that arrived while Flutter app was inactive
      await syncFromNative();
    }
  }

  /// Checks if notification access permission is granted on Android
  static Future<bool> isNotificationAccessGranted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final bool? granted =
          await _channel.invokeMethod<bool>('isNotificationAccessGranted');
      return granted ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Opens the Android Notification Access Settings screen
  static Future<void> openNotificationAccessSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod('openNotificationAccessSettings');
    } catch (e) {
      // Ignored if cannot open
    }
  }

  /// Synchronizes unprocessed notifications from Android native queue
  static Future<void> syncFromNative() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final List<dynamic>? list =
          await _channel.invokeMethod<List<dynamic>>('getUnprocessedNotifications');
      if (list != null && list.isNotEmpty) {
        for (final item in list) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            await processRawNotification(
              packageName: map['packageName']?.toString() ?? '',
              title: map['title']?.toString() ?? '',
              text: map['text']?.toString() ?? '',
              timestamp: map['timestamp'] as int?,
            );
          }
        }
      }
    } catch (e) {
      // Fallback
    }
  }

  /// Processes a single raw notification, parses it, checks deduplication, and adds to pending
  static Future<PendingTransaction?> processRawNotification({
    required String packageName,
    required String title,
    required String text,
    int? timestamp,
  }) async {
    if (!isAutoDetectEnabled) return null;

    final parsed = NotificationParser.parse(
      packageName: packageName,
      title: title,
      text: text,
      timestamp: timestamp,
    );

    if (parsed == null) return null;

    // Check if source is enabled by user
    if (!enabledSources.contains(parsed.source) && parsed.source != 'Lainnya') {
      return null;
    }

    // Anti-duplication Check 1: Already processed
    if (processedFingerprints.contains(parsed.fingerprint)) {
      return null;
    }

    // Anti-duplication Check 2: Already in pending list
    final bool alreadyInPending = pendingTransactions.any(
      (item) => item.fingerprint == parsed.fingerprint,
    );
    if (alreadyInPending) {
      return null;
    }

    final pending = parsed.toPendingTransaction();
    pendingTransactions.insert(0, pending);

    await _savePending();
    pendingCountNotifier.value = pendingTransactions.length;

    return pending;
  }

  /// Confirms a pending transaction and moves it to main transactions
  static Future<void> confirmPendingTransaction(
    PendingTransaction item, {
    String? categoryOverride,
    String? titleOverride,
    double? amountOverride,
  }) async {
    final transaction = item.toTransactionModel(
      categoryOverride: categoryOverride,
      titleOverride: titleOverride,
      amountOverride: amountOverride,
    );

    // 1. Add to existing main transaction service
    await TransactionService.addTransaction(transaction);

    // 2. Mark fingerprint as processed
    processedFingerprints.add(item.fingerprint);
    await _saveFingerprints();

    // 3. Remove from pending transactions
    pendingTransactions.removeWhere((p) => p.id == item.id);
    await _savePending();

    pendingCountNotifier.value = pendingTransactions.length;
  }

  /// Ignores a pending transaction without adding to main transactions
  static Future<void> ignorePendingTransaction(PendingTransaction item) async {
    // 1. Mark fingerprint as processed so the same notification won't pop up again
    processedFingerprints.add(item.fingerprint);
    await _saveFingerprints();

    // 2. Remove from pending list
    pendingTransactions.removeWhere((p) => p.id == item.id);
    await _savePending();

    pendingCountNotifier.value = pendingTransactions.length;
  }

  /// Clears / ignores all pending transactions
  static Future<void> clearAllPending() async {
    for (final item in pendingTransactions) {
      processedFingerprints.add(item.fingerprint);
    }
    await _saveFingerprints();

    pendingTransactions.clear();
    await _savePending();

    pendingCountNotifier.value = 0;
  }

  /// Simulation helper for manual testing and automated testing
  static Future<PendingTransaction?> simulateNotification({
    required String source,
    required String title,
    required String text,
    int? timestamp,
  }) async {
    String packageName = 'com.bca';
    if (source == 'Mandiri') packageName = 'id.bmri.livin';
    if (source == 'BRI') packageName = 'com.bri.bmo';
    if (source == 'DANA') packageName = 'id.dana';
    if (source == 'GoPay') packageName = 'com.gojek.app';
    if (source == 'OVO') packageName = 'ovo.id';
    if (source == 'ShopeePay') packageName = 'com.shopee.id';

    return await processRawNotification(
      packageName: packageName,
      title: title,
      text: text,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ============================================================
  // SETTINGS MANAGEMENT
  // ============================================================

  static Future<void> setAutoDetectEnabled(bool value) async {
    isAutoDetectEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDetect, value);
  }

  static Future<void> setConfirmRequired(bool value) async {
    isConfirmRequired = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConfirm, value);
  }

  static Future<void> setSourceEnabled(String source, bool enabled) async {
    if (enabled) {
      enabledSources.add(source);
    } else {
      enabledSources.remove(source);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySources, enabledSources.toList());
  }

  // ============================================================
  // PERSISTENCE (Safe keys that do not overwrite existing data)
  // ============================================================

  static Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isAutoDetectEnabled = prefs.getBool(_keyAutoDetect) ?? true;
    isConfirmRequired = prefs.getBool(_keyConfirm) ?? true;

    final List<String>? sources = prefs.getStringList(_keySources);
    if (sources != null && sources.isNotEmpty) {
      enabledSources = sources.toSet();
    }
  }

  static Future<void> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyPending);

    if (data == null || data.isEmpty) {
      pendingTransactions.clear();
      pendingCountNotifier.value = 0;
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);
      pendingTransactions.clear();
      pendingTransactions.addAll(
        decoded.map(
          (item) => PendingTransaction.fromJson(
            Map<String, dynamic>.from(item),
          ),
        ),
      );
      pendingCountNotifier.value = pendingTransactions.length;
    } catch (e) {
      pendingTransactions.clear();
      pendingCountNotifier.value = 0;
    }
  }

  static Future<void> _savePending() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(
      pendingTransactions.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_keyPending, data);
  }

  static Future<void> _loadFingerprints() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? list = prefs.getStringList(_keyFingerprints);
    if (list != null) {
      processedFingerprints.clear();
      processedFingerprints.addAll(list);
    }
  }

  static Future<void> _saveFingerprints() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep last 1000 fingerprints to avoid infinite growth while preserving anti-duplication
    final list = processedFingerprints.toList();
    final truncated = list.length > 1000 ? list.sublist(list.length - 1000) : list;
    await prefs.setStringList(_keyFingerprints, truncated);
  }

  /// Reset helper for testing (does not touch transactions, budgets, or categories!)
  @visibleForTesting
  static void resetForTesting() {
    pendingTransactions.clear();
    processedFingerprints.clear();
    isAutoDetectEnabled = true;
    isConfirmRequired = true;
    enabledSources = {
      'BCA',
      'BRI',
      'Mandiri',
      'DANA',
      'GoPay',
      'OVO',
      'ShopeePay',
    };
    pendingCountNotifier.value = 0;
    _isInitialized = false;
  }
}
