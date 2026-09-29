import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  final Color accentColor = const Color(0xFFE8B85C);

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String formatRupiah(double amount) {
    final value = amount.toInt().toString();

    String result = '';
    int count = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      result = value[i] + result;
      count++;

      if (count == 3 && i != 0) {
        result = '.$result';
        count = 0;
      }
    }

    return 'Rp $result';
  }

  // ============================================================
  // NAMA BULAN
  // ============================================================

  String getMonthName() {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[DateTime.now().month - 1];
  }

  // ============================================================
  // TRANSAKSI BULAN INI
  // ============================================================

  List<TransactionModel> get currentMonthTransactions {
    final now = DateTime.now();

    return TransactionService.transactions.where(
      (transaction) {
        return transaction.date.year == now.year &&
            transaction.date.month == now.month;
      },
    ).toList();
  }

  // ============================================================
  // TOTAL PEMASUKAN
  // ============================================================

  double get totalIncome {
    double total = 0;

    for (final transaction in currentMonthTransactions) {
      if (transaction.isIncome) {
        total += transaction.amount;
      }
    }

    return total;
  }

  // ============================================================
  // TOTAL PENGELUARAN
  // ============================================================

  double get totalExpense {
    double total = 0;

    for (final transaction in currentMonthTransactions) {
      if (!transaction.isIncome) {
        total += transaction.amount;
      }
    }

    return total;
  }

  // ============================================================
  // CASH FLOW
  // ============================================================

  double get cashFlow {
    return totalIncome - totalExpense;
  }

  // ============================================================
  // JUMLAH TRANSAKSI
  // ============================================================

  int get transactionCount {
    return currentMonthTransactions.length;
  }

  // ============================================================
  // RATA-RATA PENGELUARAN
  // ============================================================

  double get averageExpense {
    final expenses = currentMonthTransactions
        .where((transaction) => !transaction.isIncome)
        .length;

    if (expenses == 0) {
      return 0;
    }

    return totalExpense / expenses;
  }

  // ============================================================
  // PENGELUARAN PER KATEGORI
  // ============================================================

  Map<String, double> get expenseByCategory {
    final Map<String, double> result = {};

    for (final transaction in currentMonthTransactions) {
      if (!transaction.isIncome) {
        result[transaction.category] =
            (result[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return result;
  }

  // ============================================================
  // KATEGORI TERURUT
  // ============================================================

  List<MapEntry<String, double>> get sortedCategories {
    final entries = expenseByCategory.entries.toList();

    entries.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    return entries;
  }

  // ============================================================
  // KATEGORI TERBESAR
  // ============================================================

  String get highestCategory {
    final categories = sortedCategories;

    if (categories.isEmpty) {
      return '-';
    }

    return categories.first.key;
  }

  double get highestCategoryAmount {
    final categories = sortedCategories;

    if (categories.isEmpty) {
      return 0;
    }

    return categories.first.value;
  }

  // ============================================================
  // PERSENTASE KATEGORI
  // ============================================================

  double getCategoryPercentage(double amount) {
    if (totalExpense <= 0) {
      return 0;
    }

    return amount / totalExpense;
  }

  // ============================================================
  // WARNA KATEGORI
  // ============================================================

  Color getCategoryColor(int index) {
    const colors = [
      Color(0xFFD35B5B),
      Color(0xFFE8B85C),
      Color(0xFF5B8FD3),
      Color(0xFF2E8B57),
      Color(0xFF8B6FC4),
      Color(0xFFCC7A3A),
      Color(0xFF4B9EA8),
      Color(0xFFB45C8A),
    ];

    return colors[index % colors.length];
  }

  // ============================================================
  // ICON KATEGORI
  // ============================================================

  IconData getCategoryIcon(String categoryName) {
    for (final category in CategoryService.categories) {
      if (category['name'] == categoryName) {
        return category['icon'] as IconData? ?? Icons.category_outlined;
      }
    }

    return Icons.category_outlined;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1522) : const Color(0xFFF4F1EA);
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    final categories = sortedCategories;

    return Scaffold(
      backgroundColor: bgColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          'Statistik',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(
          color: textColor,
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Text(
                  'Ringkasan ${getMonthName()}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Lihat kondisi keuanganmu bulan ini.',
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // CASH FLOW
                // ==================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF182131) : const Color(0xFF172033),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CASH FLOW',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        formatRupiah(cashFlow),
                        style: TextStyle(
                          color: cashFlow >= 0
                              ? const Color(0xFF72C497)
                              : const Color(0xFFE98585),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        cashFlow >= 0
                            ? 'Keuangan bulan ini masih positif.'
                            : 'Pengeluaran bulan ini lebih besar dari pemasukan.',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // INCOME / EXPENSE
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Pemasukan',
                        value: formatRupiah(totalIncome),
                        icon: Icons.south_west_rounded,
                        iconColor: const Color(0xFF2E8B57),
                        background: const Color(0xFF2E8B57).withValues(alpha: isDark ? 0.20 : 0.12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Pengeluaran',
                        value: formatRupiah(totalExpense),
                        icon: Icons.north_east_rounded,
                        iconColor: const Color(0xFFD35B5B),
                        background: const Color(0xFFD35B5B).withValues(alpha: isDark ? 0.20 : 0.12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==================================================
                // TRANSACTION COUNT / AVERAGE
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Transaksi',
                        value: '$transactionCount transaksi',
                        icon: Icons.receipt_long_outlined,
                        iconColor: isDark ? accentColor : const Color(0xFF172033),
                        background: (isDark ? accentColor : const Color(0xFF172033))
                            .withValues(alpha: isDark ? 0.20 : 0.10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Rata-rata Pengeluaran',
                        value: formatRupiah(averageExpense),
                        icon: Icons.analytics_outlined,
                        iconColor: const Color(0xFFB17A2B),
                        background: const Color(0xFFB17A2B).withValues(alpha: isDark ? 0.20 : 0.15),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==================================================
                // HIGHEST CATEGORY
                // ==================================================

                Text(
                  'Kategori Terbesar',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: accentColor,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengeluaran terbesar',
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              highestCategory,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        formatRupiah(highestCategoryAmount),
                        style: const TextStyle(
                          color: Color(0xFFD35B5B),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // CATEGORY BREAKDOWN
                // ==================================================

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pengeluaran per Kategori',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${categories.length} kategori',
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ==================================================
                // EMPTY STATE
                // ==================================================

                if (categories.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 35),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 42,
                          color: mutedTextColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada pengeluaran',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data kategori akan muncul setelah kamu mencatat pengeluaran.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )

                // ==================================================
                // HORIZONTAL BAR CHART
                // ==================================================

                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // TOTAL
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total pengeluaran',
                                  style: TextStyle(
                                    color: mutedTextColor,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  formatRupiah(totalExpense),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF202A3A)
                                    : const Color(0xFFE9ECF2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${categories.length} kategori',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // BAR LIST
                        ...categories.asMap().entries.map(
                          (item) {
                            final index = item.key;
                            final entry = item.value;

                            final percentage = getCategoryPercentage(entry.value);
                            final icon = getCategoryIcon(entry.key);
                            final color = getCategoryColor(index);

                            return _CategoryBar(
                              category: entry.key,
                              amount: entry.value,
                              percentage: percentage,
                              icon: icon,
                              color: color,
                              formatRupiah: formatRupiah,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                // ==================================================
                // INFO
                // ==================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF182131) : const Color(0xFFE9ECF2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: isDark ? accentColor : const Color(0xFF172033),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Statistik di atas hanya menghitung transaksi pada bulan ${getMonthName()} tahun ini.',
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CATEGORY BAR
// ================================================================

class _CategoryBar extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;
  final IconData icon;
  final Color color;
  final String Function(double) formatRupiah;

  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.icon,
    required this.color,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatRupiah(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 9,
                    backgroundColor: isDark ? const Color(0xFF202A3A) : const Color(0xFFEDEDED),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 38,
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// STAT CARD
// ================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color background;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 19,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}