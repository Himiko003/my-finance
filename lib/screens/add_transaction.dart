import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';

class AddTransaction extends StatefulWidget {
  const AddTransaction({super.key});

  @override
  State<AddTransaction> createState() =>
      _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final Color primaryColor =
      const Color(0xFF172033);

  final Color backgroundColor =
      const Color(0xFFF4F1EA);

  final Color accentColor =
      const Color(0xFFE8B85C);

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController amountController =
      TextEditingController();

  bool isIncome = false;

  String selectedCategory = 'Makanan';

  // ============================================================
  // TANGGAL TRANSAKSI
  // ============================================================

  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> get categories =>
      CategoryService.categories;

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  // ============================================================
  // FORMAT NOMINAL
  // ============================================================

  String formatInputRupiah(String value) {
    final digits =
        value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return '';
    }

    final number = int.tryParse(digits);

    if (number == null) {
      return '';
    }

    return number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  double? parseRupiah(String value) {
    final digits =
        value.replaceAll('.', '').trim();

    if (digits.isEmpty) {
      return null;
    }

    return double.tryParse(digits);
  }

  // ============================================================
  // PILIH TANGGAL
  // ============================================================

  Future<void> selectTransactionDate() async {
    final DateTime? pickedDate =
        await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal transaksi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF172033),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF172033),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      selectedDate = pickedDate;
    });
  }

  String formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // TAMBAH KATEGORI
  // ============================================================

  Future<void> showAddCategoryDialog() async {
    final categoryController =
        TextEditingController();

    String selectedIconKey = 'category';

    final iconOptions =
        CategoryService.iconOptions;

    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Tambah Kategori',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              content: SizedBox(
                width: 420,
                height: 430,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller:
                          categoryController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Nama Kategori',
                        hintText:
                            'Contoh: Investasi',
                        prefixIcon: Icon(
                          Icons
                              .category_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Pilih Icon',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          GridView.builder(
                        itemCount:
                            iconOptions.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder:
                            (context, index) {
                          final key =
                              iconOptions.keys
                                  .elementAt(
                                      index);

                          final icon =
                              iconOptions[
                                  key]!;

                          final selected =
                              selectedIconKey ==
                                  key;

                          return InkWell(
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        14),
                            onTap: () {
                              setDialogState(
                                () {
                                  selectedIconKey =
                                      key;
                                },
                              );
                            },
                            child:
                                Container(
                              decoration:
                                  BoxDecoration(
                                color: selected
                                    ? accentColor
                                        .withValues(
                                        alpha:
                                            0.20,
                                      )
                                    : Colors
                                        .grey
                                        .shade100,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            14),
                                border:
                                    Border.all(
                                  color: selected
                                      ? accentColor
                                      : Colors
                                          .transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: selected
                                    ? primaryColor
                                    : Colors
                                        .grey
                                        .shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child:
                      const Text('Batal'),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryColor,
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed: () async {
                    final name =
                        categoryController
                            .text
                            .trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nama kategori belum diisi.',
                          ),
                        ),
                      );
                      return;
                    }

                    final success =
                        await CategoryService
                            .addCategory(
                      name,
                      iconKey:
                          selectedIconKey,
                    );

                    if (!success) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Kategori sudah ada.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  child:
                      const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    categoryController.dispose();

    if (result == true) {
      setState(() {});

      final customCategories =
          CategoryService.customCategories;

      if (customCategories.isNotEmpty) {
        setState(() {
          selectedCategory =
              customCategories.last['name']
                  .toString();
        });
      }
    }
  }

  // ============================================================
  // HAPUS KATEGORI CUSTOM
  // ============================================================

  Future<void> deleteCustomCategory(
    String categoryName,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus kategori?',
          ),
          content: Text(
            'Kategori "$categoryName" akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('Batal'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await CategoryService
        .deleteCategory(categoryName);

    if (!mounted) {
      return;
    }

    setState(() {
      if (selectedCategory ==
          categoryName) {
        selectedCategory = 'Makanan';
      }
    });
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration(
    String hint,
    IconData icon, {
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: accentColor,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // SIMPAN TRANSAKSI
  // ============================================================

  Future<void> saveTransaction() async {
    final title =
        titleController.text.trim();

    final amount =
        parseRupiah(
      amountController.text,
    );

    if (title.isEmpty ||
        amount == null ||
        amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Data transaksi belum valid.',
          ),
        ),
      );
      return;
    }

    final transaction =
        TransactionModel(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      title: title,
      category: isIncome
          ? 'Pemasukan'
          : selectedCategory,
      amount: amount,
      isIncome: isIncome,
      date: selectedDate,
    );

    await TransactionService
        .addTransaction(
      transaction,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      transaction,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor,
      appBar: AppBar(
        backgroundColor:
            backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        iconTheme:
            const IconThemeData(
          color: Color(0xFF172033),
        ),
        title: const Text(
          'Tambah Transaksi',
          style: TextStyle(
            color: Color(0xFF172033),
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              const Text(
                'Catat Transaksi',
                style: TextStyle(
                  color:
                      Color(0xFF172033),
                  fontSize: 27,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Masukkan detail transaksi kamu.',
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // JENIS TRANSAKSI
              // ==================================================

              const Text(
                'Jenis transaksi',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 9),

              Row(
                children: [
                  Expanded(
                    child:
                        GestureDetector(
                      onTap: () {
                        setState(() {
                          isIncome = true;
                        });
                      },
                      child:
                          _typeButton(
                        title:
                            'Pemasukan',
                        icon: Icons
                            .south_west_rounded,
                        selected:
                            isIncome,
                        color:
                            const Color(
                          0xFF2E8B57,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child:
                        GestureDetector(
                      onTap: () {
                        setState(() {
                          isIncome = false;

                          if (selectedCategory ==
                              'Pemasukan') {
                            selectedCategory =
                                'Makanan';
                          }
                        });
                      },
                      child:
                          _typeButton(
                        title:
                            'Pengeluaran',
                        icon: Icons
                            .north_east_rounded,
                        selected:
                            !isIncome,
                        color:
                            const Color(
                          0xFFD35B5B,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ==================================================
              // NAMA TRANSAKSI
              // ==================================================

              const Text(
                'Nama transaksi',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    titleController,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                decoration:
                    inputDecoration(
                  'Contoh: Makan siang',
                  Icons
                      .edit_note_rounded,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // NOMINAL
              // ==================================================

              const Text(
                'Nominal',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    amountController,
                keyboardType:
                    TextInputType.number,
                inputFormatters: [
                  _RupiahInputFormatter(),
                ],
                decoration:
                    inputDecoration(
                  'Contoh: 50.000',
                  Icons
                      .payments_outlined,
                  prefix: 'Rp ',
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // TANGGAL
              // ==================================================

              const Text(
                'Tanggal transaksi',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              InkWell(
                onTap:
                    selectTransactionDate,
                borderRadius:
                    BorderRadius.circular(
                        14),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 15,
                    vertical: 16,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(
                                14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .calendar_month_rounded,
                        color:
                            primaryColor,
                      ),
                      const SizedBox(
                          width: 12),
                      Expanded(
                        child: Text(
                          formatDate(
                              selectedDate),
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF172033,
                            ),
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons
                            .keyboard_arrow_down_rounded,
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // KATEGORI
              // ==================================================

              if (!isIncome) ...[
                const Text(
                  'Kategori',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                  child:
                      DropdownButtonFormField<
                          String>(
                    initialValue:
                        selectedCategory,
                    decoration:
                        const InputDecoration(
                      prefixIcon:
                          Icon(
                        Icons
                            .category_outlined,
                        color:
                            Color(
                          0xFF172033,
                        ),
                      ),
                      border:
                          InputBorder.none,
                      contentPadding:
                          EdgeInsets
                              .symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                    ),
                    items: [
                      ...categories
                          .map(
                        (
                          category,
                        ) {
                          return DropdownMenuItem<
                              String>(
                            value:
                                category[
                                    'name'],
                            child: Row(
                              children: [
                                Icon(
                                  category[
                                      'icon'],
                                  size: 19,
                                  color:
                                      primaryColor,
                                ),
                                const SizedBox(
                                    width:
                                        10),
                                Text(
                                  category[
                                      'name'],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const DropdownMenuItem<
                          String>(
                        value:
                            '__add_category__',
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .add_circle_outline,
                              color:
                                  Color(
                                0xFF172033,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Tambah Kategori',
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value ==
                          '__add_category__') {
                        showAddCategoryDialog();
                        return;
                      }

                      if (value == null) {
                        return;
                      }

                      setState(() {
                        selectedCategory =
                            value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 8),

                if (CategoryService
                    .customCategories
                    .isNotEmpty)
                  Text(
                    'Tekan lama kategori custom '
                    'untuk menghapusnya.',
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
              ],

              const SizedBox(height: 30),

              // ==================================================
              // BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      saveTransaction,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryColor,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons
                        .check_rounded,
                  ),
                  label: const Text(
                    'Simpan Transaksi',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TYPE BUTTON
  // ============================================================

  Widget _typeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required Color color,
  }) {
    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 180,
      ),
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration:
          BoxDecoration(
        color: selected
            ? color.withValues(
                alpha: 0.10,
              )
            : Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? color.withValues(
                  alpha: 0.25,
                )
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected
                ? color
                : Colors.grey,
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              color: selected
                  ? color
                  : Colors.grey.shade700,
              fontWeight:
                  FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// RUPIAH INPUT FORMATTER
// ================================================================

class _RupiahInputFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits =
        newValue.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final number =
        int.tryParse(digits);

    if (number == null) {
      return oldValue;
    }

    final formatted =
        number.toString().replaceAllMapped(
              RegExp(
                r'\B(?=(\d{3})+(?!\d))',
              ),
              (match) => '.',
            );

    return TextEditingValue(
      text: formatted,
      selection:
          TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}