import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BudgetService {
  // ============================================================
  // STORAGE
  // ============================================================

  static const String _budgetStorageKey = 'monthly_budgets';
  static const String _startDayStorageKey = 'budget_start_day';

  // Default tanggal mulai budget.
  // 25 berarti periode default:
  // 25 September - 24 Oktober
  static const int defaultStartDay = 25;

  static final Map<String, double> _budgets = {};

  static int _startDay = defaultStartDay;

  // ============================================================
  // GETTER
  // ============================================================

  static int get startDay => _startDay;

  // ============================================================
  // LOAD DATA
  // ============================================================

  static Future<void> loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();

    // ----------------------------
    // Load tanggal mulai budget
    // ----------------------------

    final savedStartDay =
        prefs.getInt(_startDayStorageKey);

    if (savedStartDay != null &&
        savedStartDay >= 1 &&
        savedStartDay <= 28) {
      _startDay = savedStartDay;
    } else {
      _startDay = defaultStartDay;
    }

    // ----------------------------
    // Load budget
    // ----------------------------

    final String? data =
        prefs.getString(_budgetStorageKey);

    if (data == null || data.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(data);

      _budgets.clear();

      decoded.forEach((key, value) {
        if (value is num) {
          _budgets[key] = value.toDouble();
        }
      });
    } catch (e) {
      _budgets.clear();
    }
  }

  // ============================================================
  // SET TANGGAL MULAI BUDGET
  // ============================================================

  static Future<bool> setStartDay(int day) async {
    // Kita batasi sampai tanggal 28 supaya semua bulan
    // tetap mempunyai tanggal tersebut.
    //
    // Contoh:
    // tanggal 29 bisa bermasalah pada bulan Februari.
    if (day < 1 || day > 28) {
      return false;
    }

    _startDay = day;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setInt(
      _startDayStorageKey,
      _startDay,
    );

    return true;
  }

  // ============================================================
  // PERIODE BUDGET
  // ============================================================

  /// Mengambil tanggal mulai periode budget
  /// berdasarkan tanggal yang diberikan.
  ///
  /// Contoh startDay = 25:
  ///
  /// 20 September
  /// -> periode dimulai 25 Agustus
  ///
  /// 25 September
  /// -> periode dimulai 25 September
  static DateTime getPeriodStart(
    DateTime date,
  ) {
    if (date.day >= _startDay) {
      return DateTime(
        date.year,
        date.month,
        _startDay,
      );
    }

    return DateTime(
      date.year,
      date.month - 1,
      _startDay,
    );
  }

  /// Mengambil tanggal akhir periode budget.
  ///
  /// Tanggal akhir adalah satu hari sebelum
  /// periode berikutnya dimulai.
  ///
  /// Contoh:
  /// startDay = 25
  ///
  /// 25 September
  /// ->
  /// 24 Oktober
  static DateTime getPeriodEnd(
    DateTime date,
  ) {
    final start = getPeriodStart(date);

    return DateTime(
      start.year,
      start.month + 1,
      _startDay - 1,
    );
  }

  /// Membuat key unik berdasarkan periode budget.
  ///
  /// Contoh:
  /// 25 September 2026
  /// -> 2026-9
  ///
  /// Jadi budget periode:
  /// 25 Sep - 24 Okt
  /// disimpan menggunakan key tersebut.
  static String getPeriodKey(
    DateTime date,
  ) {
    final start = getPeriodStart(date);

    return '${start.year}-${start.month}';
  }

  // ============================================================
  // GET BUDGET
  // ============================================================

  static double getBudget(
    DateTime date,
  ) {
    final key = getPeriodKey(date);

    return _budgets[key] ?? 2000000;
  }

  // ============================================================
  // SET BUDGET
  // ============================================================

  static Future<void> setBudget(
    DateTime date,
    double amount,
  ) async {
    final key = getPeriodKey(date);

    _budgets[key] = amount;

    await _saveBudgets();
  }

  // ============================================================
  // SAVE BUDGET
  // ============================================================

  static Future<void> _saveBudgets() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String data =
        jsonEncode(_budgets);

    await prefs.setString(
      _budgetStorageKey,
      data,
    );
  }

  // ============================================================
  // FORMAT PERIODE
  // ============================================================

  static String getPeriodLabel(
    DateTime date,
  ) {
    final start = getPeriodStart(date);
    final end = getPeriodEnd(date);

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${start.day} ${months[start.month - 1]} '
        '${start.year} - '
        '${end.day} ${months[end.month - 1]} '
        '${end.year}';
  }

  // ============================================================
  // RESET KE DEFAULT
  // ============================================================

  static Future<void> resetStartDay() async {
    _startDay = defaultStartDay;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setInt(
      _startDayStorageKey,
      defaultStartDay,
    );
  }
}