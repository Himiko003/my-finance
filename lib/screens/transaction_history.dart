import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  String selectedFilter = 'Semua';

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

  List<TransactionModel> get filteredTransactions {
    final transactions = TransactionService.transactions;

    if (selectedFilter == 'Pemasukan') {
      return transactions.where((transaction) => transaction.isIncome).toList();
    }

    if (selectedFilter == 'Pengeluaran') {
      return transactions.where((transaction) => !transaction.isIncome).toList();
    }

    return transactions;
  }

  void editTransaction(TransactionModel transaction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final iconColor = isDark ? const Color(0xFFE8B85C) : const Color(0xFF172033);
    final accentColor = const Color(0xFFE8B85C);
    final primaryBtnColor = isDark ? accentColor : const Color(0xFF172033);
    final primaryBtnTextColor = isDark ? const Color(0xFF172033) : Colors.white;

    final titleController = TextEditingController(text: transaction.title);
    final amountController = TextEditingController(
      text: _formatInputRupiah(transaction.amount),
    );

    String selectedType = transaction.isIncome ? 'Pemasukan' : 'Pengeluaran';
    String selectedCategory = transaction.category;
    final categories = CategoryService.categories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bool isIncome = selectedType == 'Pemasukan';

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Edit Transaksi',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Jenis transaksi',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedType = 'Pemasukan';
                                selectedCategory = 'Pemasukan';
                              });
                            },
                            child: _typeButton(
                              title: 'Pemasukan',
                              icon: Icons.south_west_rounded,
                              selected: isIncome,
                              color: const Color(0xFF2E8B57),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedType = 'Pengeluaran';
                                if (selectedCategory == 'Pemasukan') {
                                  selectedCategory = 'Makanan';
                                }
                              });
                            },
                            child: _typeButton(
                              title: 'Pengeluaran',
                              icon: Icons.north_east_rounded,
                              selected: !isIncome,
                              color: const Color(0xFFD35B5B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Nama transaksi',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        'Nama transaksi',
                        Icons.edit_note_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Nominal',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      inputFormatters: [
                        _RupiahInputFormatter(),
                      ],
                      decoration: _inputDecoration(
                        'Nominal',
                        Icons.payments_outlined,
                        prefix: 'Rp ',
                      ),
                    ),
                    if (!isIncome) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Kategori',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: categories.any(
                          (category) => category['name'] == selectedCategory,
                        )
                            ? selectedCategory
                            : categories.first['name'].toString(),
                        dropdownColor: cardColor,
                        iconEnabledColor: textColor,
                        decoration: _inputDecoration(
                          'Kategori',
                          Icons.category_outlined,
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['name'].toString(),
                            child: Row(
                              children: [
                                Icon(
                                  category['icon'],
                                  size: 18,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category['name'].toString(),
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final amount = _parseRupiah(amountController.text);

                          if (title.isEmpty || amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data transaksi tidak valid'),
                              ),
                            );
                            return;
                          }

                          final updated = TransactionModel(
                            id: transaction.id,
                            title: title,
                            category: selectedCategory,
                            amount: amount,
                            isIncome: isIncome,
                            date: transaction.date,
                          );

                          TransactionService.updateTransaction(updated);

                          setState(() {});
                          Navigator.pop(sheetContext);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaksi diperbarui'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBtnColor,
                          foregroundColor: primaryBtnTextColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void deleteTransaction(TransactionModel transaction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFFD35B5B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD35B5B),
                  size: 27,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Hapus transaksi?',
                style: TextStyle(
                  color: textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Transaksi "${transaction.title}" akan dihapus secara permanen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        TransactionService.deleteTransaction(transaction.id);
                        setState(() {});
                        Navigator.pop(sheetContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaksi dihapus'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD35B5B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1522) : const Color(0xFFF4F1EA);
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    final transactions = filteredTransactions;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        iconTheme: IconThemeData(color: textColor),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF172033),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Text(
              'Riwayat',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                children: [
                  Text(
                    'Aktivitas',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Semua transaksi yang sudah kamu catat.',
                    style: TextStyle(
                      color: mutedTextColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Masuk',
                          amount: formatRupiah(TransactionService.totalIncome),
                          icon: Icons.south_west_rounded,
                          color: const Color(0xFF2E8B57),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Keluar',
                          amount: formatRupiah(TransactionService.totalExpense),
                          icon: Icons.north_east_rounded,
                          color: const Color(0xFFD35B5B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterButton('Semua'),
                        const SizedBox(width: 8),
                        _filterButton('Pemasukan'),
                        const SizedBox(width: 8),
                        _filterButton('Pengeluaran'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (transactions.isEmpty)
                    _emptyState()
                  else
                    ...transactions.map(
                      (transaction) {
                        return _TransactionCard(
                          transaction: transaction,
                          formatRupiah: formatRupiah,
                          onEdit: () {
                            editTransaction(transaction);
                          },
                          onDelete: () {
                            deleteTransaction(transaction);
                          },
                          monthName: monthName,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade700;
    final accentColor = const Color(0xFFE8B85C);
    final activeBtnColor = isDark ? accentColor : const Color(0xFF172033);
    final activeTextColor = isDark ? const Color(0xFF172033) : Colors.white;

    final selected = selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? activeBtnColor : cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: selected ? activeTextColor : mutedTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final inputBgColor = isDark ? const Color(0xFF202A3A) : const Color(0xFFF4F1EA);
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: inputBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 30,
              color: mutedTextColor,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Transaksi yang kamu tambahkan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    String? prefix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBgColor = isDark ? const Color(0xFF202A3A) : Colors.white;
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;
    final iconColor = isDark ? const Color(0xFFE8B85C) : const Color(0xFF172033);
    final accentColor = const Color(0xFFE8B85C);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: mutedTextColor),
      prefixText: prefix,
      prefixStyle: prefix != null
          ? TextStyle(color: accentColor, fontWeight: FontWeight.w700)
          : null,
      prefixIcon: Icon(
        icon,
        color: iconColor,
      ),
      filled: true,
      fillColor: inputBgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _typeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade700;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: isDark ? 0.20 : 0.10)
            : cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? color.withValues(alpha: isDark ? 0.50 : 0.25)
              : (isDark ? Colors.white10 : Colors.transparent),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 17,
            color: selected ? color : mutedTextColor,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: selected ? color : mutedTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  amount,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(int) monthName;

  const _TransactionCard({
    required this.transaction,
    required this.formatRupiah,
    required this.onEdit,
    required this.onDelete,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    final bool isIncome = transaction.isIncome;
    final Color color = isIncome ? const Color(0xFF2E8B57) : const Color(0xFFD35B5B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${transaction.date.day} ${monthName(transaction.date.month)} ${transaction.date.year}',
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: cardColor,
            icon: Icon(
              Icons.more_vert_rounded,
              color: mutedTextColor,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              }
              if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 19,
                        color: textColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit',
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        size: 19,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Hapus',
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

String _formatInputRupiah(double amount) {
  final digits = amount.toInt().toString();

  return digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
}

double? _parseRupiah(String value) {
  final digits = value.replaceAll('.', '').trim();

  if (digits.isEmpty) {
    return null;
  }

  return double.tryParse(digits);
}

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