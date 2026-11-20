import 'package:flutter/material.dart';

import '../models/pending_transaction.dart';
import '../services/notification_service.dart';
import '../services/category_service.dart';
import '../services/notification_parser.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  bool _hasNotificationAccess = false;

  final List<Map<String, dynamic>> _sources = [
    {'name': 'BCA', 'color': const Color(0xFF005DAA), 'icon': Icons.account_balance},
    {'name': 'BRI', 'color': const Color(0xFF00529C), 'icon': Icons.account_balance},
    {'name': 'Mandiri', 'color': const Color(0xFF003876), 'icon': Icons.account_balance},
    {'name': 'BNI', 'color': const Color(0xFFF15A23), 'icon': Icons.account_balance},
    {'name': 'Bank Jago', 'color': const Color(0xFFFEAE00), 'icon': Icons.account_balance},
    {'name': 'DANA', 'color': const Color(0xFF118EEA), 'icon': Icons.account_balance_wallet},
    {'name': 'GoPay', 'color': const Color(0xFF00AA13), 'icon': Icons.wallet},
    {'name': 'OVO', 'color': const Color(0xFF4C2A86), 'icon': Icons.wallet},
    {'name': 'ShopeePay', 'color': const Color(0xFFEE4D2D), 'icon': Icons.shopping_bag_outlined},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
      NotificationService.syncFromNative().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.isNotificationAccessGranted();
    if (mounted) {
      setState(() {
        _hasNotificationAccess = granted;
      });
    }
  }

  String _formatRupiah(double amount) {
    final numberString = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;

    for (int i = numberString.length - 1; i >= 0; i--) {
      buffer.write(numberString[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  String _formatDateTime(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  Color _getSourceColor(String source) {
    for (final s in _sources) {
      if (s['name'] == source) return s['color'] as Color;
    }
    return const Color(0xFF172033);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color pageBackground =
        isDark ? const Color(0xFF0F1522) : const Color(0xFFF4F1EA);
    final Color cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final Color inputColor =
        isDark ? const Color(0xFF202A3A) : const Color(0xFFF4F1EA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF172033);
    final Color mutedTextColor =
        isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;
    const Color goldAccent = Color(0xFFE8B85C);
    const Color primaryNavy = Color(0xFF172033);
    final Color primaryBtnColor = isDark ? goldAccent : primaryNavy;
    final Color primaryBtnTextColor = isDark ? primaryNavy : Colors.white;

    final pendingList = NotificationService.pendingTransactions;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'Auto Detect Transaksi',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Simulasi Notifikasi',
            icon: Icon(Icons.science_outlined, color: isDark ? goldAccent : primaryNavy),
            onPressed: () => _showSimulationDialog(isDark, cardColor, inputColor, textColor, mutedTextColor),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            // HEADER INTRO CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isDark ? goldAccent : primaryNavy).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: isDark ? goldAccent : primaryNavy,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto Detect Transaksi',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mendeteksi transaksi dari notifikasi bank dan e-wallet.',
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // STATUS TOGGLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Fitur',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: NotificationService.isAutoDetectEnabled
                                      ? const Color(0xFF72C497)
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                NotificationService.isAutoDetectEnabled
                                    ? 'Aktif'
                                    : 'Tidak Aktif',
                                style: TextStyle(
                                  color: NotificationService.isAutoDetectEnabled
                                      ? const Color(0xFF72C497)
                                      : mutedTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: NotificationService.isAutoDetectEnabled,
                        activeTrackColor: isDark ? goldAccent : primaryNavy,
                        onChanged: (val) async {
                          await NotificationService.setAutoDetectEnabled(val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // NOTIFICATION ACCESS PERMISSION CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasNotificationAccess
                      ? const Color(0xFF72C497).withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notification Access',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _hasNotificationAccess
                              ? const Color(0xFF72C497).withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _hasNotificationAccess
                              ? 'Terhubung'
                              : 'Belum Terhubung',
                          style: TextStyle(
                            color: _hasNotificationAccess
                                ? const Color(0xFF72C497)
                                : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_hasNotificationAccess) ...[
                    Text(
                      'Notification Access diperlukan agar MyFinance dapat mendeteksi notifikasi transaksi dari aplikasi bank & e-wallet.',
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBtnColor,
                          foregroundColor: primaryBtnTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await NotificationService.openNotificationAccessSettings();
                        },
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text(
                          'Aktifkan Notification Access',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Izin notifikasi aktif. Notifikasi transaksi bank dan e-wallet akan diproses secara otomatis di latar belakang.',
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // KONFIRMASI TRANSAKSI CARD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Transaksi',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Review transaksi sebelum dimasukkan ke pencatatan utama',
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: NotificationService.isConfirmRequired,
                    activeTrackColor: isDark ? goldAccent : primaryNavy,
                    onChanged: (val) async {
                      await NotificationService.setConfirmRequired(val);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SUMBER NOTIFIKASI
            Text(
              'Sumber Notifikasi',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _sources.length; i++) ...[
                    CheckboxListTile(
                      dense: true,
                      activeColor: isDark ? goldAccent : primaryNavy,
                      checkColor: isDark ? primaryNavy : Colors.white,
                      secondary: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (_sources[i]['color'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _sources[i]['icon'] as IconData,
                          color: _sources[i]['color'] as Color,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        _sources[i]['name'] as String,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      value: NotificationService.enabledSources
                          .contains(_sources[i]['name']),
                      onChanged: (bool? checked) async {
                        await NotificationService.setSourceEnabled(
                          _sources[i]['name'] as String,
                          checked ?? false,
                        );
                        setState(() {});
                      },
                    ),
                    if (i < _sources.length - 1)
                      Divider(height: 1, indent: 64, color: mutedTextColor.withValues(alpha: 0.15)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // TRANSAKSI TERDETEKSI SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Transaksi Terdeteksi',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: pendingList.isNotEmpty
                            ? (isDark ? goldAccent : primaryNavy)
                            : mutedTextColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pendingList.length}',
                        style: TextStyle(
                          color: pendingList.isNotEmpty
                              ? (isDark ? primaryNavy : Colors.white)
                              : mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (pendingList.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: cardColor,
                          title: Text('Abaikan Semua?', style: TextStyle(color: textColor)),
                          content: Text(
                            'Semua transaksi terdeteksi yang belum disimpan akan diabaikan.',
                            style: TextStyle(color: mutedTextColor),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Batal', style: TextStyle(color: mutedTextColor)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE98585),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Abaikan Semua'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await NotificationService.clearAllPending();
                        setState(() {});
                      }
                    },
                    child: Text(
                      'Abaikan Semua',
                      style: TextStyle(
                        color: const Color(0xFFE98585),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // PENDING TRANSACTIONS LIST
            if (pendingList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: mutedTextColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi terdeteksi',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notifikasi dari bank dan e-wallet yang aktif akan muncul di sini untuk dikonfirmasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final pending in pendingList) ...[
                _buildPendingCard(
                  pending: pending,
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                  mutedTextColor: mutedTextColor,
                  primaryBtnColor: primaryBtnColor,
                  primaryBtnTextColor: primaryBtnTextColor,
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard({
    required PendingTransaction pending,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color mutedTextColor,
    required Color primaryBtnColor,
    required Color primaryBtnTextColor,
  }) {
    final sourceColor = _getSourceColor(pending.source);
    final amountColor = pending.isIncome
        ? const Color(0xFF72C497)
        : const Color(0xFFE98585);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SOURCE & TYPE HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sourceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pending.source,
                      style: TextStyle(
                        color: sourceColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white12 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pending.category,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                _formatDateTime(pending.date),
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // TITLE & AMOUNT
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pending.title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${pending.isIncome ? '+' : '-'} ${_formatRupiah(pending.amount)}',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          if (pending.rawText != null && pending.rawText!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              pending.rawText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: mutedTextColor,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ACTION BUTTONS: [ Abaikan ] [ Simpan ] + Edit Dialog
          Row(
            children: [
              IconButton(
                tooltip: 'Edit data transaksi',
                icon: Icon(Icons.edit_outlined, size: 20, color: mutedTextColor),
                onPressed: () => _showEditPendingDialog(pending),
              ),
              const Spacer(),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: mutedTextColor,
                  side: BorderSide(color: mutedTextColor.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () async {
                  await NotificationService.ignorePendingTransaction(pending);
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaksi diabaikan'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Abaikan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBtnColor,
                  foregroundColor: primaryBtnTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                onPressed: () async {
                  await NotificationService.confirmPendingTransaction(pending);
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaksi berhasil disimpan ke pencatatan utama!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPendingDialog(PendingTransaction pending) async {
    final titleController = TextEditingController(text: pending.title);
    String selectedCategory = pending.category;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final inputColor = isDark ? const Color(0xFF202A3A) : const Color(0xFFF4F1EA);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;

    final categoryNames = CategoryService.categories
        .map((cat) => cat['name'] as String)
        .toList();
    if (!categoryNames.contains('Lainnya')) {
      categoryNames.add('Lainnya');
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Edit Transaksi', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Judul Transaksi', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Kategori', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: categoryNames.contains(selectedCategory)
                          ? selectedCategory
                          : (categoryNames.isNotEmpty ? categoryNames.first : 'Lainnya'),
                      dropdownColor: cardColor,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: categoryNames.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat, style: TextStyle(color: textColor)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Batal', style: TextStyle(color: mutedTextColor)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await NotificationService.confirmPendingTransaction(
                      pending,
                      titleOverride: titleController.text.trim(),
                      categoryOverride: selectedCategory,
                    );
                    setState(() {});
                  },
                  child: const Text('Simpan ke Transaksi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSimulationDialog(
    bool isDark,
    Color cardColor,
    Color inputColor,
    Color textColor,
    Color mutedTextColor,
  ) async {
    String selectedSource = 'BCA';
    final titleController = TextEditingController(text: 'Transfer Masuk');
    final textController = TextEditingController(text: 'Transfer masuk Rp500.000 dari BUDI UTOMO');

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.science_outlined, color: Color(0xFFE8B85C)),
                  const SizedBox(width: 8),
                  Text('Tes Simulasi Notifikasi', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih Sumber:', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSource,
                      dropdownColor: cardColor,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: NotificationParser.supportedSources.map((s) {
                        return DropdownMenuItem<String>(
                          value: s,
                          child: Text(s, style: TextStyle(color: textColor)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedSource = val;
                            if (val == 'GoPay') {
                              titleController.text = 'Pembayaran Berhasil';
                              textController.text = 'Pembayaran GoFood sebesar Rp 45.000 ke Kopi Kenangan';
                            } else if (val == 'DANA') {
                              titleController.text = 'DANA QRIS';
                              textController.text = 'Pembayaran QRIS sebesar Rp 25.000 di Alfamart berhasil';
                            } else if (val == 'BCA') {
                              titleController.text = 'Transfer Masuk';
                              textController.text = 'Transfer masuk Rp500.000 dari BUDI UTOMO';
                            } else if (val == 'Mandiri') {
                              titleController.text = 'Livin Mandiri';
                              textController.text = 'Debit Rp 1.500.000 untuk tagihan PLN';
                            } else if (val == 'Bank Jago') {
                              titleController.text = 'Bank Jago';
                              textController.text = 'Uang masuk Rp 500.000 ke Kantong Utama dari BUDI';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Judul Notifikasi:', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Isi Notifikasi:', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Tutup', style: TextStyle(color: mutedTextColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8B85C),
                    foregroundColor: const Color(0xFF172033),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    final result = await NotificationService.simulateNotification(
                      source: selectedSource,
                      title: titleController.text.trim(),
                      text: textController.text.trim(),
                    );
                    if (!mounted) return;
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          result != null
                              ? 'Berhasil mendeteksi transaksi: ${result.title} (${_formatRupiah(result.amount)})'
                              : 'Notifikasi ditolak (duplikat atau nominal tidak terdeteksi)',
                        ),
                      ),
                    );
                  },
                  child: const Text('Kirim Notifikasi Tes', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
