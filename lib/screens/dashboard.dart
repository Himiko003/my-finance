import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/budget_service.dart';
import '../widgets/transaction_item.dart';

import 'add_transaction.dart';
import 'savings_goal.dart';
import 'financial_calendar.dart';
import 'transaction_history.dart';
import 'statistics.dart';
import 'notification_settings.dart';
import '../services/notification_service.dart';

class Dashboard extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const Dashboard({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  final Color primaryColor = const Color(0xFF172033);
  final Color backgroundColor = const Color(0xFFF4F1EA);
  final Color accentColor = const Color(0xFFE8B85C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.syncFromNative().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  // ============================================================
  // DATA UTAMA
  // ============================================================

  double get monthlyBudget {
    return BudgetService.getBudget(DateTime.now());
  }

  double get totalIncome {
    return TransactionService.totalIncome;
  }

  double get totalExpense {
    return TransactionService.totalExpense;
  }

  double get totalBalance {
    return TransactionService.totalBalance;
  }

  // ============================================================
  // DATA BULAN BERJALAN
  // ============================================================

  double get currentMonthIncome {
    final now = DateTime.now();

    return getMonthlyIncome(
      now.year,
      now.month,
    );
  }

  double get currentMonthExpense {
    final now = DateTime.now();

    return getMonthlyExpense(
      now.year,
      now.month,
    );
  }

  // ============================================================
  // DATA BUDGET PERIOD
  // ============================================================

  DateTime get budgetPeriodStart {
    return BudgetService.getPeriodStart(
      DateTime.now(),
    );
  }

  DateTime get budgetPeriodEnd {
    return BudgetService.getPeriodEnd(
      DateTime.now(),
    );
  }

  double get budgetPeriodExpense {
    final start = DateTime(
      budgetPeriodStart.year,
      budgetPeriodStart.month,
      budgetPeriodStart.day,
    );

    final endExclusive = DateTime(
      budgetPeriodEnd.year,
      budgetPeriodEnd.month,
      budgetPeriodEnd.day,
    ).add(
      const Duration(days: 1),
    );

    double total = 0;

    for (final transaction in TransactionService.transactions) {
      final transactionDate = transaction.date;

      if (!transaction.isIncome &&
          !transactionDate.isBefore(start) &&
          transactionDate.isBefore(endExclusive)) {
        total += transaction.amount;
      }
    }

    return total;
  }

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
  // FORMAT INPUT RUPIAH
  // ============================================================

  double? parseRupiah(String value) {
    final digits = value
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    if (digits.isEmpty) {
      return null;
    }

    return double.tryParse(digits);
  }

  // ============================================================
  // NAMA BULAN
  // ============================================================

  String getMonthName(int month) {
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

  String getShortMonthName(int month) {
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

    return months[month - 1];
  }

  // ============================================================
  // FORMAT PERIODE
  // ============================================================

  String getBudgetPeriodLabel() {
    final start = budgetPeriodStart;
    final end = budgetPeriodEnd;

    if (start.year == end.year) {
      return '${start.day} ${getShortMonthName(start.month)}'
          ' - '
          '${end.day} ${getShortMonthName(end.month)}';
    }

    return '${start.day} ${getShortMonthName(start.month)} '
        '${start.year}'
        ' - '
        '${end.day} ${getShortMonthName(end.month)} '
        '${end.year}';
  }

  String getBudgetPeriodFullLabel() {
    final start = budgetPeriodStart;
    final end = budgetPeriodEnd;

    return '${start.day} ${getMonthName(start.month)} '
        '${start.year}'
        ' - '
        '${end.day} ${getMonthName(end.month)} '
        '${end.year}';
  }

  // ============================================================
  // BUDGET DIALOG
  // ============================================================

  Future<void> openBudgetDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;
    final inputColor = isDark ? const Color(0xFF202A3A) : const Color(0xFFF4F1EA);
    final primaryBtnColor = isDark ? accentColor : const Color(0xFF172033);
    final primaryBtnTextColor = isDark ? const Color(0xFF172033) : Colors.white;

    final controller = TextEditingController(
      text: monthlyBudget.toInt().toString(),
    );

    int selectedStartDay = BudgetService.startDay;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewStart = _getPreviewPeriodStart(selectedStartDay);
            final previewEnd = _getPreviewPeriodEnd(selectedStartDay);

            return AlertDialog(
              backgroundColor: cardColor,
              title: Text(
                'Atur Budget',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tentukan nominal dan tanggal mulai periode budget.',
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TANGGAL MULAI
                    Text(
                      'Tanggal mulai budget',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: inputColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedStartDay,
                          isExpanded: true,
                          dropdownColor: cardColor,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: textColor,
                          ),
                          items: List.generate(
                            28,
                            (index) {
                              final day = index + 1;

                              return DropdownMenuItem<int>(
                                value: day,
                                child: Text(
                                  'Tanggal $day',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            },
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedStartDay = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Periode: '
                      '${previewStart.day} '
                      '${getShortMonthName(previewStart.month)} '
                      '${previewStart.year}'
                      ' - '
                      '${previewEnd.day} '
                      '${getShortMonthName(previewEnd.month)} '
                      '${previewEnd.year}',
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // NOMINAL BUDGET
                    Text(
                      'Budget pengeluaran',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),

                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      inputFormatters: [
                        _RupiahInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                          color: isDark ? accentColor : primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: 'Contoh: 2.000.000',
                        hintStyle: TextStyle(color: mutedTextColor),
                        filled: true,
                        fillColor: inputColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(color: mutedTextColor),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBtnColor,
                    foregroundColor: primaryBtnTextColor,
                  ),
                  onPressed: () async {
                    final amount = parseRupiah(controller.text);

                    if (amount == null || amount <= 0) return;

                    await BudgetService.setStartDay(selectedStartDay);
                    await BudgetService.setBudget(DateTime.now(), amount);

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // PREVIEW PERIOD
  // ============================================================

  DateTime _getPreviewPeriodStart(int startDay) {
    final now = DateTime.now();

    if (now.day >= startDay) {
      return DateTime(
        now.year,
        now.month,
        startDay,
      );
    }

    return DateTime(
      now.year,
      now.month - 1,
      startDay,
    );
  }

  DateTime _getPreviewPeriodEnd(int startDay) {
    final start = _getPreviewPeriodStart(startDay);

    return DateTime(
      start.year,
      start.month + 1,
      startDay - 1,
    );
  }

  // ============================================================
  // DATA GRAFIK
  // ============================================================

  List<String> getMonthLabels() {
    final now = DateTime.now();
    final labels = <String>[];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month - i,
        1,
      );

      labels.add(
        getShortMonthName(date.month),
      );
    }

    return labels;
  }

  double getMonthlyIncome(int year, int month) {
    double total = 0;

    for (final transaction in TransactionService.transactions) {
      if (transaction.isIncome &&
          transaction.date.year == year &&
          transaction.date.month == month) {
        total += transaction.amount;
      }
    }

    return total;
  }

  double getMonthlyExpense(int year, int month) {
    double total = 0;

    for (final transaction in TransactionService.transactions) {
      if (!transaction.isIncome &&
          transaction.date.year == year &&
          transaction.date.month == month) {
        total += transaction.amount;
      }
    }

    return total;
  }

  List<BarChartGroupData> buildChartData() {
    final now = DateTime.now();
    final groups = <BarChartGroupData>[];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month - i,
        1,
      );

      final income = getMonthlyIncome(date.year, date.month);
      final expense = getMonthlyExpense(date.year, date.month);

      groups.add(
        BarChartGroupData(
          x: 5 - i,
          barsSpace: 5,
          barRods: [
            BarChartRodData(
              toY: income,
              width: 9,
              color: const Color(0xFF72C497),
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: expense,
              width: 9,
              color: const Color(0xFFE98585),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  double getChartMaxY() {
    final now = DateTime.now();
    double highest = 0;

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month - i,
        1,
      );

      final income = getMonthlyIncome(date.year, date.month);
      final expense = getMonthlyExpense(date.year, date.month);

      if (income > highest) highest = income;
      if (expense > highest) highest = expense;
    }

    if (highest <= 0) return 100;

    return highest * 1.2;
  }

  // ============================================================
  // NAVIGASI
  // ============================================================

  Future<void> addNewTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransaction(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Statistics(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openSavingsGoal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavingsGoal(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openFinancialCalendar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FinancialCalendar(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openTransactionHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionHistory(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color pageBackground = isDark ? const Color(0xFF0F1522) : const Color(0xFFF4F1EA);
    final Color cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF172033);
    final Color mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;
    final Color primaryBtnColor = isDark ? accentColor : primaryColor;
    final Color primaryBtnTextColor = isDark ? const Color(0xFF172033) : Colors.white;

    final double budgetProgress = monthlyBudget > 0
        ? (budgetPeriodExpense / monthlyBudget).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final double budgetRemaining =
        monthlyBudget - budgetPeriodExpense > 0
            ? monthlyBudget - budgetPeriodExpense
            : 0;

    final bool budgetExceeded = budgetPeriodExpense > monthlyBudget;
    final double overBudgetAmount = budgetPeriodExpense - monthlyBudget;

    final transactions = TransactionService.transactions;
    final chartGroups = buildChartData();
    final chartMaxY = getChartMaxY();
    final monthLabels = getMonthLabels();

    return Scaffold(
      backgroundColor: pageBackground,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: pageBackground,
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
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Text(
              'MyFinance',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              onPressed: widget.onToggleTheme,
              icon: Icon(
                widget.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: textColor,
              ),
            ),
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.pendingCountNotifier,
            builder: (context, pendingCount, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Auto Detect Transaksi',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    icon: Icon(
                      pendingCount > 0
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: pendingCount > 0
                          ? (isDark ? accentColor : primaryColor)
                          : textColor,
                    ),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE98585),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          pendingCount > 9 ? '9+' : '$pendingCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // GREETING
              // ==================================================

              Text(
                'Halo, Bro 👋',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Ini ringkasan keuanganmu.',
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // TOTAL SALDO
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL SALDO',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      formatRupiah(totalBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _BalanceInfo(
                            label: 'Pemasukan',
                            value: formatRupiah(currentMonthIncome),
                            color: const Color(0xFF72C497),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 35,
                          color: Colors.white12,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: _BalanceInfo(
                              label: 'Pengeluaran',
                              value: formatRupiah(currentMonthExpense),
                              color: const Color(0xFFE98585),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // NOTIFIKASI TRANSAKSI TERDETEKSI BANNER
              // ==================================================
              ValueListenableBuilder<int>(
                valueListenable: NotificationService.pendingCountNotifier,
                builder: (context, pendingCount, _) {
                  if (pendingCount == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsScreen(),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: (isDark ? accentColor : primaryColor)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? accentColor.withValues(alpha: 0.4)
                                : primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? accentColor : primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 18,
                                color: isDark ? primaryColor : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$pendingCount Transaksi Terdeteksi',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ada transaksi dari notifikasi yang perlu dikonfirmasi',
                                    style: TextStyle(
                                      color: mutedTextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark ? accentColor : primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ==================================================
              // AKSES CEPAT
              // ==================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Akses Cepat',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: openTransactionHistory,
                    child: Text(
                      'History',
                      style: TextStyle(
                        color: isDark ? accentColor : primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      title: 'Tambah',
                      icon: Icons.add_rounded,
                      color: isDark ? accentColor : primaryColor,
                      onTap: addNewTransaction,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      title: 'Statistik',
                      icon: Icons.analytics_outlined,
                      color: const Color(0xFF7A5AF8),
                      onTap: openStatistics,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      title: 'Kalender',
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFFB17A2B),
                      onTap: openFinancialCalendar,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      title: 'Tabungan',
                      icon: Icons.savings_outlined,
                      color: const Color(0xFF2E8B57),
                      onTap: openSavingsGoal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==================================================
              // BUDGET
              // ==================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget Pengeluaran',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: openBudgetDialog,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: isDark ? accentColor : primaryColor,
                    ),
                    label: Text(
                      'Atur',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? accentColor : primaryColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.25 : 0.18),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getBudgetPeriodLabel(),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Mulai tanggal ${BudgetService.startDay}',
                                style: TextStyle(
                                  color: mutedTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              budgetExceeded
                                  ? 'Melewati'
                                  : '${(budgetProgress * 100).toInt()}%',
                              style: TextStyle(
                                color: budgetExceeded
                                    ? Colors.red
                                    : (isDark ? accentColor : primaryColor),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (budgetExceeded)
                              const Text(
                                'Budget terlampaui',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 9,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // NOMINAL BUDGET
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatRupiah(monthlyBudget),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: budgetProgress,
                        minHeight: 9,
                        backgroundColor: isDark ? const Color(0xFF202A3A) : const Color(0xFFEDEDED),
                        color: budgetExceeded
                            ? Colors.red
                            : (isDark ? accentColor : primaryColor),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terpakai ${formatRupiah(budgetPeriodExpense)}',
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          budgetExceeded
                              ? 'Lebih ${formatRupiah(overBudgetAmount)}'
                              : 'Sisa ${formatRupiah(budgetRemaining)}',
                          style: TextStyle(
                            color: budgetExceeded ? Colors.red : mutedTextColor,
                            fontSize: 11,
                            fontWeight: budgetExceeded ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    if (budgetExceeded) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pengeluaran sudah melewati budget periode ini.',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFE98585) : Colors.red.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // GRAFIK
              // ==================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktivitas Keuangan',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '6 bulan',
                    style: TextStyle(
                      color: mutedTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Container(
                height: 285,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 20, 20, 10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ChartLegend(
                          color: const Color(0xFF72C497),
                          label: 'Pemasukan',
                        ),
                        const SizedBox(width: 16),
                        _ChartLegend(
                          color: const Color(0xFFE98585),
                          label: 'Pengeluaran',
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: BarChart(
                        BarChartData(
                          maxY: chartMaxY,
                          minY: 0,
                          alignment: BarChartAlignment.spaceAround,
                          groupsSpace: 18,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: chartMaxY / 4,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.withValues(alpha: 0.12),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 25,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();

                                  if (index < 0 || index >= monthLabels.length) {
                                    return const SizedBox();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      monthLabels[index],
                                      style: TextStyle(
                                        color: mutedTextColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: chartGroups,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => isDark
                                  ? const Color(0xFF202A3A)
                                  : const Color(0xFF172033),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final type = rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';

                                return BarTooltipItem(
                                  '$type\n${formatRupiah(rod.toY)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // TRANSAKSI TERBARU
              // ==================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (transactions.isNotEmpty)
                    GestureDetector(
                      onTap: openTransactionHistory,
                      child: Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: isDark ? accentColor : Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              if (transactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 38,
                        color: mutedTextColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tambahkan transaksi pertamamu.',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...transactions.take(4).map(
                  (TransactionModel transaction) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TransactionItem(
                        icon: transaction.isIncome
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        title: transaction.title,
                        category: transaction.category,
                        amount:
                            '${transaction.isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}',
                        isIncome: transaction.isIncome,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),

      // ========================================================
      // FLOATING ACTION BUTTON
      // ========================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addNewTransaction,
        backgroundColor: primaryBtnColor,
        foregroundColor: primaryBtnTextColor,
        elevation: 3,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// RUPIAH INPUT FORMATTER
// ================================================================

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final number = int.tryParse(digits);

    if (number == null) {
      return oldValue;
    }

    final formatted = number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}

// ================================================================
// BALANCE INFO
// ================================================================

class _BalanceInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BalanceInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// QUICK ACTION
// ================================================================

class _QuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.20 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CHART LEGEND
// ================================================================

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: mutedTextColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}