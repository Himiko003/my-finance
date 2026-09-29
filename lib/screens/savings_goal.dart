import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsGoal extends StatefulWidget {
  const SavingsGoal({super.key});

  @override
  State<SavingsGoal> createState() => _SavingsGoalState();
}

class _SavingsGoalState extends State<SavingsGoal> {
  static const String _storageKey = 'savings_goals';

  final Color accentColor = const Color(0xFFE8B85C);

  List<Map<String, dynamic>> goals = [];

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

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

  String formatInputRupiah(double amount) {
    final digits = amount.toInt().toString();

    return digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  double? parseRupiah(String value) {
    final digits = value.replaceAll('.', '').trim();

    if (digits.isEmpty) {
      return null;
    }

    return double.tryParse(digits);
  }

  Future<void> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data == null || data.isEmpty) {
      if (mounted) {
        setState(() {
          goals = [];
        });
      }
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);

      if (mounted) {
        setState(() {
          goals = decoded.map((item) {
            final map = Map<String, dynamic>.from(item);

            return {
              'title': map['title']?.toString() ?? 'Target',
              'target': (map['target'] as num?)?.toDouble() ?? 0,
              'saved': (map['saved'] as num?)?.toDouble() ?? 0,
              'deadline': map['deadline']?.toString(),
              'iconKey': map['iconKey']?.toString() ?? 'savings',
            };
          }).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          goals = [];
        });
      }
    }
  }

  Future<void> saveGoals() async {
    final prefs = await SharedPreferences.getInstance();

    final data = goals.map((goal) {
      return {
        'title': goal['title'],
        'target': goal['target'],
        'saved': goal['saved'],
        'deadline': goal['deadline'],
        'iconKey': goal['iconKey'] ?? 'savings',
      };
    }).toList();

    await prefs.setString(
      _storageKey,
      jsonEncode(data),
    );
  }

  IconData getGoalIcon(String? iconKey) {
    switch (iconKey) {
      case 'laptop':
        return Icons.laptop_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'phone':
        return Icons.phone_android_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'travel':
        return Icons.travel_explore_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  Future<void> showAddGoalDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final inputBgColor = isDark ? const Color(0xFF202A3A) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;
    final iconColor = isDark ? const Color(0xFFE8B85C) : const Color(0xFF172033);
    final primaryBtnColor = isDark ? accentColor : const Color(0xFF172033);
    final primaryBtnTextColor = isDark ? const Color(0xFF172033) : Colors.white;

    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final savedController = TextEditingController();

    DateTime? selectedDeadline;
    String selectedIcon = 'savings';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              title: Text(
                'Tambah Target',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Nama Target',
                        labelStyle: TextStyle(color: mutedTextColor),
                        hintText: 'Contoh: Beli Laptop',
                        hintStyle: TextStyle(color: mutedTextColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      inputFormatters: [
                        _RupiahInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Target Dana',
                        labelStyle: TextStyle(color: mutedTextColor),
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: savedController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      inputFormatters: [
                        _RupiahInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Dana Terkumpul',
                        labelStyle: TextStyle(color: mutedTextColor),
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Icon Target',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'savings',
                        'laptop',
                        'flight',
                        'home',
                        'car',
                        'phone',
                        'education',
                        'travel',
                      ].map((key) {
                        final selected = selectedIcon == key;

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = key;
                            });
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: selected
                                  ? accentColor.withValues(alpha: 0.20)
                                  : inputBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? accentColor : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              getGoalIcon(key),
                              color: selected ? accentColor : iconColor,
                              size: 20,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDeadline ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: isDark
                                    ? ColorScheme.dark(
                                        primary: accentColor,
                                        onPrimary: const Color(0xFF172033),
                                        surface: cardColor,
                                        onSurface: textColor,
                                      )
                                    : const ColorScheme.light(
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

                        if (picked != null) {
                          setDialogState(() {
                            selectedDeadline = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Deadline',
                          labelStyle: TextStyle(color: mutedTextColor),
                          prefixIcon: Icon(
                            Icons.event_outlined,
                            color: iconColor,
                          ),
                          filled: true,
                          fillColor: inputBgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        child: Text(
                          selectedDeadline == null
                              ? 'Tidak ada deadline'
                              : formatDate(selectedDeadline!),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
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
                    final title = titleController.text.trim();
                    final target = parseRupiah(targetController.text);
                    final saved = parseRupiah(savedController.text);

                    if (title.isEmpty ||
                        target == null ||
                        target <= 0 ||
                        saved == null ||
                        saved < 0) {
                      showMessage('Data target belum valid.');
                      return;
                    }

                    if (saved > target) {
                      showMessage(
                        'Dana terkumpul tidak boleh lebih besar dari target.',
                      );
                      return;
                    }

                    setState(() {
                      goals.add({
                        'title': title,
                        'target': target,
                        'saved': saved,
                        'deadline': selectedDeadline?.toIso8601String(),
                        'iconKey': selectedIcon,
                      });
                    });

                    await saveGoals();

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
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

    titleController.dispose();
    targetController.dispose();
    savedController.dispose();
  }

  Future<void> addFunds(int index) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final inputBgColor = isDark ? const Color(0xFF202A3A) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;
    final primaryBtnColor = isDark ? accentColor : const Color(0xFF172033);
    final primaryBtnTextColor = isDark ? const Color(0xFF172033) : Colors.white;

    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            'Tambah Dana',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: textColor),
            inputFormatters: [
              _RupiahInputFormatter(),
            ],
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nominal',
              labelStyle: TextStyle(color: mutedTextColor),
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
              hintText: 'Contoh: 250.000',
              hintStyle: TextStyle(color: mutedTextColor),
              filled: true,
              fillColor: inputBgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
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

                if (amount == null || amount <= 0) {
                  showMessage('Nominal belum valid.');
                  return;
                }

                final target = (goals[index]['target'] as num).toDouble();
                final saved = (goals[index]['saved'] as num).toDouble();

                if (saved + amount > target) {
                  showMessage(
                    'Dana melebihi target. Sisa target ${formatRupiah(target - saved)}.',
                  );
                  return;
                }

                setState(() {
                  goals[index]['saved'] = saved + amount;
                });

                await saveGoals();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> deleteGoal(int index) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            'Hapus target?',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Target "${goals[index]['title']}" akan dihapus.',
            style: TextStyle(color: textColor),
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      goals.removeAt(index);
    });

    await saveGoals();
  }

  String formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String getDeadlineText(dynamic deadline) {
    if (deadline == null || deadline.toString().isEmpty) {
      return 'Tanpa deadline';
    }

    final date = DateTime.tryParse(deadline.toString());

    if (date == null) {
      return 'Tanpa deadline';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(date.year, date.month, date.day);
    final difference = deadlineDate.difference(today).inDays;

    if (difference < 0) {
      return 'Deadline lewat';
    }

    if (difference == 0) {
      return 'Deadline hari ini';
    }

    if (difference == 1) {
      return '1 hari lagi';
    }

    return '$difference hari lagi';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget buildGoalCard(Map<String, dynamic> goal, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;
    final iconColor = isDark ? const Color(0xFFE8B85C) : const Color(0xFF172033);

    final target = (goal['target'] as num).toDouble();
    final saved = (goal['saved'] as num).toDouble();
    final progress = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
    final remaining = (target - saved).clamp(0.0, double.infinity);
    final completed = saved >= target;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.25 : 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  getGoalIcon(goal['iconKey']?.toString()),
                  color: iconColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['title'].toString(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      completed
                          ? 'Target tercapai 🎉'
                          : getDeadlineText(goal['deadline']),
                      style: TextStyle(
                        color: completed ? const Color(0xFF2E8B57) : mutedTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
                  if (value == 'add') {
                    addFunds(index);
                  }
                  if (value == 'delete') {
                    deleteGoal(index);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: textColor,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Tambah Dana',
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatRupiah(saved),
                style: const TextStyle(
                  color: Color(0xFF2E8B57),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                formatRupiah(target),
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: isDark ? const Color(0xFF202A3A) : const Color(0xFFEDEDED),
              color: completed ? const Color(0xFF2E8B57) : accentColor,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% tercapai',
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                completed ? 'Selesai' : 'Kurang ${formatRupiah(remaining)}',
                style: TextStyle(
                  color: completed ? const Color(0xFF2E8B57) : mutedTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1522) : const Color(0xFFF4F1EA);
    final cardColor = isDark ? const Color(0xFF182131) : const Color(0xFF172033);
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;
    final primaryBtnColor = isDark ? accentColor : const Color(0xFF172033);
    final primaryBtnTextColor = isDark ? const Color(0xFF172033) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          'Target Tabungan',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(
          color: textColor,
        ),
      ),
      body: goals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 58,
                      color: mutedTextColor,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Belum ada target tabungan',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Buat target pertama kamu dan mulai pantau progresnya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: showAddGoalDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBtnColor,
                        foregroundColor: primaryBtnTextColor,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Target'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.savings_rounded,
                          color: Color(0xFFE8B85C),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Target Tabungan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${goals.length} target aktif',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...goals.asMap().entries.map(
                      (entry) => buildGoalCard(
                        entry.value,
                        entry.key,
                      ),
                    ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddGoalDialog,
        backgroundColor: primaryBtnColor,
        foregroundColor: primaryBtnTextColor,
        child: const Icon(Icons.add),
      ),
    );
  }
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