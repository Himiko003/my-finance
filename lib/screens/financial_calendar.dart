import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class FinancialCalendar extends StatefulWidget {
  const FinancialCalendar({super.key});

  @override
  State<FinancialCalendar> createState() =>
      _FinancialCalendarState();
}

class _FinancialCalendarState
    extends State<FinancialCalendar> {
  DateTime selectedMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  final Color primaryColor = const Color(0xFF172033);
  final Color backgroundColor = const Color(0xFFF4F1EA);
  final Color accentColor = const Color(0xFFE8B85C);

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

  String monthName(int month) {
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

    return months[month - 1];
  }

  List<TransactionModel> getTransactionsForDate(
    DateTime date,
  ) {
    return TransactionService.transactions
        .where(
          (transaction) =>
              transaction.date.year == date.year &&
              transaction.date.month == date.month &&
              transaction.date.day == date.day,
        )
        .toList();
  }

  bool hasTransaction(DateTime date) {
    return TransactionService.transactions.any(
      (transaction) =>
          transaction.date.year == date.year &&
          transaction.date.month == date.month &&
          transaction.date.day == date.day,
    );
  }

  double get selectedIncome {
    return getTransactionsForDate(selectedDate)
        .where((transaction) => transaction.isIncome)
        .fold(
          0,
          (sum, transaction) =>
              sum + transaction.amount,
        );
  }

  double get selectedExpense {
    return getTransactionsForDate(selectedDate)
        .where((transaction) => !transaction.isIncome)
        .fold(
          0,
          (sum, transaction) =>
              sum + transaction.amount,
        );
  }

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
        1,
      );

      selectedDate = selectedMonth;
    });
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        1,
      );

      selectedDate = selectedMonth;
    });
  }

  List<DateTime?> generateCalendarDays() {
    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final lastDay = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    );

    final daysInMonth = lastDay.day;

    final firstWeekday = firstDay.weekday - 1;

    final List<DateTime?> days = [];

    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }

    for (int day = 1; day <= daysInMonth; day++) {
      days.add(
        DateTime(
          selectedMonth.year,
          selectedMonth.month,
          day,
        ),
      );
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final calendarDays = generateCalendarDays();
    final selectedTransactions =
        getTransactionsForDate(selectedDate);

    final selectedBalance =
        selectedIncome - selectedExpense;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius:
                    BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Keuangan',
              style: TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // HEADER
              const Text(
                'Catatan Harian',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Pantau aktivitas keuangan berdasarkan tanggal.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 22),

              // MONTH SELECTOR
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: previousMonth,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            monthName(
                              selectedMonth.month,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${selectedMonth.year}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: nextMonth,
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // CALENDAR
              Container(
                padding:
                    const EdgeInsets.fromLTRB(
                  14,
                  18,
                  14,
                  18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black
                        .withOpacity(0.04),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        _DayTitle('S'),
                        _DayTitle('S'),
                        _DayTitle('R'),
                        _DayTitle('K'),
                        _DayTitle('J'),
                        _DayTitle('S'),
                        _DayTitle('M'),
                      ],
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount:
                          calendarDays.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 7,
                        crossAxisSpacing: 5,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder:
                          (context, index) {
                        final date =
                            calendarDays[index];

                        if (date == null) {
                          return const SizedBox();
                        }

                        final isSelected =
                            date.year ==
                                    selectedDate
                                        .year &&
                                date.month ==
                                    selectedDate
                                        .month &&
                                date.day ==
                                    selectedDate.day;

                        final hasData =
                            hasTransaction(date);

                        final isToday =
                            date.year ==
                                    DateTime.now()
                                        .year &&
                                date.month ==
                                    DateTime.now()
                                        .month &&
                                date.day ==
                                    DateTime.now()
                                        .day;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDate = date;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 180,
                            ),
                            decoration:
                                BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : isToday
                                      ? const Color(
                                          0xFFFFF3D6,
                                        )
                                      : Colors
                                          .transparent,
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight
                                                .w800
                                            : FontWeight
                                                .w600,
                                    color: isSelected
                                        ? Colors.white
                                        : primaryColor,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                if (hasData)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration:
                                        BoxDecoration(
                                      color: isSelected
                                          ? accentColor
                                          : primaryColor,
                                      shape:
                                          BoxShape.circle,
                                    ),
                                  )
                                else
                                  const SizedBox(
                                    height: 5,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SELECTED DATE
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dipilih',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${selectedDate.day} '
                        '${monthName(selectedDate.month)} '
                        '${selectedDate.year}',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${selectedTransactions.length} transaksi',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // DAILY SUMMARY
              Row(
                children: [
                  Expanded(
                    child: _SummaryBox(
                      label: 'Masuk',
                      amount:
                          formatRupiah(selectedIncome),
                      color: const Color(0xFF2E8B57),
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryBox(
                      label: 'Keluar',
                      amount:
                          formatRupiah(selectedExpense),
                      color: const Color(0xFFD35B5B),
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryBox(
                      label: 'Selisih',
                      amount:
                          formatRupiah(selectedBalance),
                      color: primaryColor,
                      icon: Icons.swap_vert_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TRANSACTIONS
              if (selectedTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 35,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.grey.shade500,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Belum ada catatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Tidak ada transaksi pada tanggal ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...selectedTransactions.map(
                  (transaction) {
                    return _TransactionCard(
                      transaction: transaction,
                      formatRupiah: formatRupiah,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayTitle extends StatelessWidget {
  final String title;

  const _DayTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryBox({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            amount,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final String Function(double) formatRupiah;

  const _TransactionCard({
    required this.transaction,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;

    final color = isIncome
        ? const Color(0xFF2E8B57)
        : const Color(0xFFD35B5B);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              isIncome
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: color,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${isIncome ? '+' : '-'} '
            '${formatRupiah(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}