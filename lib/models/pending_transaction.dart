import 'transaction_model.dart';

class PendingTransaction {
  final String id;
  final String fingerprint;
  final String source;
  final String title;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final DateTime createdAt;
  final String? rawText;

  PendingTransaction({
    required this.id,
    required this.fingerprint,
    required this.source,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.createdAt,
    this.rawText,
  });

  PendingTransaction copyWith({
    String? id,
    String? fingerprint,
    String? source,
    String? title,
    String? category,
    double? amount,
    bool? isIncome,
    DateTime? date,
    DateTime? createdAt,
    String? rawText,
  }) {
    return PendingTransaction(
      id: id ?? this.id,
      fingerprint: fingerprint ?? this.fingerprint,
      source: source ?? this.source,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      isIncome: isIncome ?? this.isIncome,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      rawText: rawText ?? this.rawText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fingerprint': fingerprint,
      'source': source,
      'title': title,
      'category': category,
      'amount': amount,
      'isIncome': isIncome,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'rawText': rawText,
    };
  }

  factory PendingTransaction.fromJson(Map<String, dynamic> json) {
    return PendingTransaction(
      id: json['id'] ?? '',
      fingerprint: json['fingerprint'] ?? '',
      source: json['source'] ?? 'Lainnya',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Lainnya',
      amount: (json['amount'] as num).toDouble(),
      isIncome: json['isIncome'] ?? false,
      date: DateTime.parse(json['date']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      rawText: json['rawText'],
    );
  }

  TransactionModel toTransactionModel({
    String? titleOverride,
    String? categoryOverride,
    double? amountOverride,
  }) {
    return TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleOverride ?? (title.isNotEmpty ? title : source),
      category: categoryOverride ?? category,
      amount: amountOverride ?? amount,
      isIncome: isIncome,
      date: date,
    );
  }
}
