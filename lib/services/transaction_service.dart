import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';

class TransactionService {
  static final List<TransactionModel> transactions = [];

  static const String _storageKey =
      'transactions';

  static double get totalIncome {
    double total = 0;

    for (final transaction in transactions) {
      if (transaction.isIncome) {
        total += transaction.amount;
      }
    }

    return total;
  }

  static double get totalExpense {
    double total = 0;

    for (final transaction in transactions) {
      if (!transaction.isIncome) {
        total += transaction.amount;
      }
    }

    return total;
  }

  static double get totalBalance {
    return totalIncome - totalExpense;
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  static Future<void> loadTransactions() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? data =
        prefs.getString(_storageKey);

    if (data == null || data.isEmpty) {
      return;
    }

    try {
      final List<dynamic> decoded =
          jsonDecode(data);

      transactions.clear();

      transactions.addAll(
        decoded.map(
          (item) => TransactionModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        ),
      );
    } catch (e) {
      // Jika data rusak, aplikasi tetap bisa berjalan
      transactions.clear();
    }
  }

  // ============================================================
  // SAVE DATA
  // ============================================================

  static Future<void> _saveTransactions() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String data = jsonEncode(
      transactions
          .map(
            (transaction) =>
                transaction.toJson(),
          )
          .toList(),
    );

    await prefs.setString(
      _storageKey,
      data,
    );
  }

  // ============================================================
  // ADD
  // ============================================================

  static Future<void> addTransaction(
    TransactionModel transaction,
  ) async {
    transactions.insert(
      0,
      transaction,
    );

    await _saveTransactions();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  static Future<void> updateTransaction(
    TransactionModel transaction,
  ) async {
    final index =
        transactions.indexWhere(
      (item) => item.id == transaction.id,
    );

    if (index != -1) {
      transactions[index] =
          transaction;

      await _saveTransactions();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  static Future<void> deleteTransaction(
    String id,
  ) async {
    transactions.removeWhere(
      (transaction) =>
          transaction.id == id,
    );

    await _saveTransactions();
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  static Future<void> clearTransactions() async {
    transactions.clear();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _storageKey,
    );
  }
}