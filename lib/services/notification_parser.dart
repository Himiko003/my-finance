import '../models/pending_transaction.dart';

class ParsedTransaction {
  final String source;
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String category;
  final String fingerprint;
  final String? rawText;

  ParsedTransaction({
    required this.source,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.category,
    required this.fingerprint,
    this.rawText,
  });

  PendingTransaction toPendingTransaction() {
    return PendingTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fingerprint: fingerprint,
      source: source,
      title: title,
      category: category,
      amount: amount,
      isIncome: isIncome,
      date: date,
      createdAt: DateTime.now(),
      rawText: rawText,
    );
  }
}

class NotificationParser {
  /// Known bank and e-wallet package name mappings
  static const Map<String, String> packageToSource = {
    'com.bca': 'BCA',
    'com.bca.mybca': 'BCA',
    'mybca.bca.co.id': 'BCA',
    'id.bmri.livin': 'Mandiri',
    'com.bri.bmo': 'BRI',
    'id.co.bni.newmbanking': 'BNI',
    'com.jago.digitalBanking': 'Bank Jago',
    'id.dana': 'DANA',
    'com.gojek.app': 'GoPay',
    'com.gopay.wallet': 'GoPay',
    'ovo.id': 'OVO',
    'com.shopee.id': 'ShopeePay',
  };

  /// Supported sources list
  static const List<String> supportedSources = [
    'BCA',
    'BRI',
    'Mandiri',
    'BNI',
    'Bank Jago',
    'DANA',
    'GoPay',
    'OVO',
    'ShopeePay',
  ];

  /// Main parse method
  static ParsedTransaction? parse({
    required String packageName,
    required String title,
    required String text,
    int? timestamp,
  }) {
    final combinedText = '$title $text'.trim();
    if (combinedText.isEmpty) return null;

    if (shouldIgnoreNotification(combinedText)) {
      return null;
    }

    final double? amount = extractAmount(combinedText);
    if (amount == null || amount <= 0) {
      return null;
    }

    final String source = detectSource(packageName: packageName, title: title, text: text);
    final bool isIncome = detectIsIncome(combinedText);
    final DateTime date = timestamp != null && timestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : DateTime.now();

    final String cleanTitle = extractCleanTitle(title: title, text: text, isIncome: isIncome, source: source);
    final String category = detectCategory(combinedText: combinedText, isIncome: isIncome);
    final String fingerprint = generateFingerprint(
      source: source,
      amount: amount,
      isIncome: isIncome,
      date: date,
      title: cleanTitle,
      packageName: packageName,
    );

    return ParsedTransaction(
      source: source,
      title: cleanTitle,
      amount: amount,
      isIncome: isIncome,
      date: date,
      category: category,
      fingerprint: fingerprint,
      rawText: combinedText,
    );
  }

  /// Detects the source bank / e-wallet
  static String detectSource({
    required String packageName,
    required String title,
    required String text,
  }) {
    // 1. Direct package match
    if (packageToSource.containsKey(packageName)) {
      return packageToSource[packageName]!;
    }

    final lower = '$packageName $title $text'.toLowerCase();

    // 2. Keyword detection
    if (lower.contains('bca') || lower.contains('mybca') || lower.contains('klikbca')) {
      return 'BCA';
    }
    if (lower.contains('bri') || lower.contains('brimo')) {
      return 'BRI';
    }
    if (lower.contains('mandiri') || lower.contains('livin')) {
      return 'Mandiri';
    }
    if (lower.contains('dana')) {
      return 'DANA';
    }
    if (lower.contains('gopay') || lower.contains('gojek')) {
      return 'GoPay';
    }
    if (lower.contains('ovo')) {
      return 'OVO';
    }
    if (lower.contains('shopeepay') || lower.contains('shopee pay') || lower.contains('shopee')) {
      return 'ShopeePay';
    }
    if (lower.contains('bni')) {
      return 'BNI';
    }
    if (lower.contains('bank jago') || RegExp(r'\bjago\b').hasMatch(lower)) {
      return 'Bank Jago';
    }

    return 'Lainnya';
  }

  /// Filters out non-transactional notifications (OTP, failed/cancelled, marketing promos)
  static bool shouldIgnoreNotification(String text) {
    final lower = text.toLowerCase();

    // 1. OTP / verification / security codes
    final otpPatterns = [
      RegExp(r'\botp\b'),
      RegExp(r'\bkode\s+verifikasi\b'),
      RegExp(r'\bverification\s+code\b'),
      RegExp(r'\bkode\s+keamanan\b'),
      RegExp(r'\bjangan\s+(?:bagikan|berikan)\s+kode\b'),
      RegExp(r'\bpin\s+transaksi\b'),
    ];
    for (final pattern in otpPatterns) {
      if (pattern.hasMatch(lower)) return true;
    }

    // 2. Failed, cancelled, expired, or pending-payment notifications
    const failedOrCancelledPhrases = [
      'transaksi gagal',
      'pembayaran gagal',
      'transfer gagal',
      'top up gagal',
      'gagal diproses',
      'tidak berhasil',
      'belum berhasil',
      'dibatalkan',
      'cancelled',
      'canceled',
      'kadaluarsa',
      'kedaluwarsa',
      'expired',
      'ditolak',
      'declined',
      'rejected',
      'menunggu pembayaran',
      'selesaikan pembayaran',
    ];
    for (final phrase in failedOrCancelledPhrases) {
      if (lower.contains(phrase)) return true;
    }

    // 3. Marketing / promotional notifications without completed transaction signals
    const promoPhrases = [
      'diskon hingga',
      'cashback hingga',
      'promo spesial',
      'kode promo',
      'klaim sekarang',
      'dapatkan cashback',
      'nikmati diskon',
      'syarat & ketentuan',
      's&k berlaku',
      'penawaran spesial',
      'yuk transaksi',
      'buruan',
    ];
    const completedSignals = [
      'berhasil',
      'sukses',
      'telah ditambahkan',
      'diterima',
      'didebit',
      'dikredit',
      'transfer masuk',
      'transfer keluar',
    ];
    final hasPromoPhrase = promoPhrases.any(lower.contains);
    if (hasPromoPhrase && !completedSignals.any(lower.contains)) {
      return true;
    }

    return false;
  }

  /// Extracts transaction amount from text with Indonesian currency format priority
  static double? extractAmount(String text) {
    // 1. Match patterns explicitly preceded by Rp, IDR
    final rpPattern = RegExp(
      r'(?:Rp\.?|IDR)\s*([0-9\.,]+)',
      caseSensitive: false,
    );
    for (final match in rpPattern.allMatches(text)) {
      final parsed = parseFormattedNumber(match.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }

    // 2. Match patterns near transaction keywords: "sebesar 50.000", "nominal 100.000", "jumlah 25.000"
    final keywordPattern = RegExp(
      r'(?:sebesar|nominal|total|jumlah|nilai|harga)\s*(?:Rp\.?|IDR)?\s*([0-9\.,]+)',
      caseSensitive: false,
    );
    for (final match in keywordPattern.allMatches(text)) {
      final parsed = parseFormattedNumber(match.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }

    // 3. Match general Indonesian number formats like 1.500.000 or 25.000
    final generalPattern = RegExp(
      r'(?:^|\s)([0-9]{1,3}(?:[\.,][0-9]{3})+(?:[\.,][0-9]{2})?)(?:\s|$|\.|,)',
    );
    for (final match in generalPattern.allMatches(text)) {
      final parsed = parseFormattedNumber(match.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }

    return null;
  }

  /// Parses a formatted number string (handles 1.500.000, 25.000, 25,000, 1.500.000,00, etc.)
  static double? parseFormattedNumber(String raw) {
    String cleaned = raw.trim();
    // Remove trailing dot or comma if accidental
    while (cleaned.endsWith('.') || cleaned.endsWith(',')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    if (cleaned.isEmpty) return null;

    final hasDot = cleaned.contains('.');
    final hasComma = cleaned.contains(',');

    // Case 1: Both dot and comma present (e.g. 1.500.000,00 or 1,500,000.00)
    if (hasDot && hasComma) {
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');

      if (lastDot < lastComma) {
        // Indonesian format: 1.500.000,00 -> dot is thousand separator, comma is decimal
        final noDots = cleaned.replaceAll('.', '');
        final standard = noDots.replaceAll(',', '.');
        return double.tryParse(standard);
      } else {
        // US format: 1,500,000.00 -> comma is thousand separator, dot is decimal
        final noCommas = cleaned.replaceAll(',', '');
        return double.tryParse(noCommas);
      }
    }

    // Case 2: Only dots present (e.g. 1.500.000 or 25.000 or 25.50)
    if (hasDot && !hasComma) {
      final parts = cleaned.split('.');
      if (parts.length > 2) {
        // Multiple dots -> definitely thousand separator (e.g. 1.500.000)
        return double.tryParse(parts.join(''));
      } else if (parts.length == 2) {
        // Single dot (e.g. 25.000 or 25.50)
        if (parts[1].length == 3) {
          // Thousand separator in Indonesian (e.g. 25.000)
          return double.tryParse('${parts[0]}${parts[1]}');
        } else {
          // Decimal separator
          return double.tryParse(cleaned);
        }
      }
    }

    // Case 3: Only commas present (e.g. 1,500,000 or 25,000 or 25,50)
    if (hasComma && !hasDot) {
      final parts = cleaned.split(',');
      if (parts.length > 2) {
        // Multiple commas -> thousand separator
        return double.tryParse(parts.join(''));
      } else if (parts.length == 2) {
        if (parts[1].length == 3) {
          // Thousands separator (e.g. 25,000)
          return double.tryParse('${parts[0]}${parts[1]}');
        } else {
          // Decimal separator (e.g. 25,50 -> 25.5)
          return double.tryParse('${parts[0]}.${parts[1]}');
        }
      }
    }

    // Plain digits without separator
    return double.tryParse(cleaned);
  }

  /// Determines if transaction is Income (true) or Expense (false)
  static bool detectIsIncome(String text) {
    final lower = text.toLowerCase();

    // 1. Explicit outgoing subject context (e.g. "Kamu telah melakukan transfer ke ...", "Kamu mengirim ... ke ...")
    final outgoingSubjectPatterns = [
      RegExp(r'\b(?:kamu|anda)\s+(?:telah\s+)?(?:melakukan\s+transfer|mengirim|kirim|transfer)\b'),
    ];
    for (final pattern in outgoingSubjectPatterns) {
      if (pattern.hasMatch(lower)) {
        return false;
      }
    }

    // 2. Context-aware incoming patterns (e.g. "telah mengirim Rp50.000 ke kamu", "transfer ke rekening kamu")
    final incomingContextPatterns = [
      RegExp(r'\b(?:telah\s+)?mengirim(?:\s+uang|\s+dana)?\b.*\b(?:ke|kepada)\s+(?:rekening\s+|kantong\s+|akun\s+)?(?:kamu|anda)\b'),
      RegExp(r'\btransfer\b.*\b(?:ke|kepada)\s+(?:rekening\s+|kantong\s+|akun\s+)?(?:kamu|anda)\b'),
    ];
    for (final pattern in incomingContextPatterns) {
      if (pattern.hasMatch(lower)) {
        return true;
      }
    }

    // 3. Specific strong income phrases
    final strongIncomePhrases = [
      'transfer masuk',
      'dana masuk',
      'uang masuk',
      'top up berhasil',
      'saldo masuk',
      'saldo bertambah',
      'kantong bertambah',
      'telah masuk',
      'telah ditambahkan',
      'berhasil diisi',
      'cashback',
      'refund',
      'pengembalian dana',
      'menerima transfer',
      'penerimaan',
      'terima uang',
      'dana diterima',
      'uang diterima',
      'credited',
      'payment received',
      'incoming transfer',
      'cash in',
      'menerima dana',
    ];

    for (final phrase in strongIncomePhrases) {
      if (lower.contains(phrase)) {
        return true;
      }
    }

    // Specific strong expense phrases
    final strongExpensePhrases = [
      'transfer keluar',
      'uang keluar',
      'transfer ke',
      'berhasil ditransfer ke',
      'berhasil dikirim',
      'berhasil kirim',
      'kamu mengirim',
      'pembayaran',
      'bayar',
      'qris',
      'kirim uang',
      'pembelian',
      'belanja',
      'tarik tunai',
      'tarik saldo',
      'cash out',
      'auto debit',
      'autodebet',
      'biaya admin',
      'debit',
      'debited',
      'purchase',
      'tagihan',
      'sent to',
      'paid to',
    ];

    for (final phrase in strongExpensePhrases) {
      if (lower.contains(phrase)) {
        return false;
      }
    }

    // General income keywords
    final incomeKeywords = [
      'masuk',
      'menerima',
      'diterima',
      'credit',
      'received',
    ];

    for (final kw in incomeKeywords) {
      if (lower.contains(kw)) {
        return true;
      }
    }

    // Default to expense (false)
    return false;
  }

  /// Suggests a category based on notification keywords
  static String detectCategory({
    required String combinedText,
    required bool isIncome,
  }) {
    final lower = combinedText.toLowerCase();

    if (isIncome) {
      if (lower.contains('gaji') || lower.contains('payroll') || lower.contains('salary')) {
        return 'Gaji';
      }
      return 'Lainnya';
    }

    // Expense categories
    // 1. Makanan
    final foodKeywords = [
      'makan',
      'resto',
      'restoran',
      'cafe',
      'kopi',
      'coffee',
      'food',
      'gofood',
      'grabfood',
      'shopeefood',
      'bakso',
      'indomaret',
      'alfamart',
      'roti',
      'burger',
      'pizza',
      'mie',
      'warung',
      'dapur',
      'culinary',
    ];
    for (final kw in foodKeywords) {
      if (lower.contains(kw)) return 'Makanan';
    }

    // 2. Transportasi
    final transportKeywords = [
      'spbu',
      'bensin',
      'pertamina',
      'shell',
      'goride',
      'gocar',
      'grab',
      'maxim',
      'krl',
      'mrt',
      'toll',
      'tol',
      'parkir',
      'ojek',
      'kereta',
      'pesawat',
      'tiket',
    ];
    for (final kw in transportKeywords) {
      if (lower.contains(kw)) return 'Transportasi';
    }

    // 3. Belanja
    final shoppingKeywords = [
      'shopee',
      'tokopedia',
      'lazada',
      'tiktok shop',
      'blibli',
      'supermarket',
      'mall',
      'matahari',
      'uniqlo',
      'zara',
      'belanja',
      'pasar',
    ];
    for (final kw in shoppingKeywords) {
      if (lower.contains(kw)) return 'Belanja';
    }

    // 4. Hiburan
    final entertainmentKeywords = [
      'netflix',
      'spotify',
      'steam',
      'bioskop',
      'cinema',
      'xxi',
      'game',
      'youtube',
      'playstation',
      'disney',
      'nintendo',
    ];
    for (final kw in entertainmentKeywords) {
      if (lower.contains(kw)) return 'Hiburan';
    }

    // 5. Tagihan
    final billKeywords = [
      'pln',
      'listrik',
      'pdam',
      'air',
      'bpjs',
      'wifi',
      'indihome',
      'pulsa',
      'telkomsel',
      'indosat',
      'xl',
      'smartfren',
      'tagihan',
    ];
    for (final kw in billKeywords) {
      if (lower.contains(kw)) return 'Tagihan';
    }

    // If QRIS without specific merchant category, default to Makanan
    if (lower.contains('qris')) {
      return 'Makanan';
    }

    return 'Lainnya';
  }

  /// Extracts a human-friendly title
  static String extractCleanTitle({
    required String title,
    required String text,
    required bool isIncome,
    required String source,
  }) {
    final cleanT = title.trim();
    if (cleanT.isNotEmpty &&
        cleanT != source &&
        cleanT.toLowerCase() != 'jago' &&
        !cleanT.toLowerCase().contains('myfinance')) {
      return cleanT;
    }

    final lower = text.toLowerCase();
    if (lower.contains('qris')) {
      return 'Pembayaran QRIS';
    }
    if (isIncome) {
      if (lower.contains('top up')) {
        return 'Top Up Masuk';
      }
      if (lower.contains('transfer') ||
          lower.contains('uang masuk') ||
          lower.contains('mengirim')) {
        return 'Transfer Masuk';
      }
      return 'Pemasukan $source';
    }
    if (lower.contains('transfer ke') ||
        lower.contains('transfer keluar') ||
        lower.contains('uang keluar') ||
        lower.contains('mengirim') ||
        lower.contains('berhasil kirim')) {
      return 'Transfer Keluar';
    }
    if (lower.contains('pembayaran')) {
      return 'Pembayaran';
    }
    if (lower.contains('top up')) {
      return 'Top Up';
    }

    return 'Pengeluaran $source';
  }

  /// Generates a deterministic fingerprint to prevent duplicate processing
  static String generateFingerprint({
    required String source,
    required double amount,
    required bool isIncome,
    required DateTime date,
    required String title,
    required String packageName,
  }) {
    // Normalizes to 1-minute window so multiple callbacks for the exact same event produce identical fingerprint
    final dateKey = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_'
        '${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';

    final normalizedTitle = title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final amountKey = amount.toStringAsFixed(0);
    final typeKey = isIncome ? 'IN' : 'OUT';

    return 'fp_${source}_${packageName}_${amountKey}_${typeKey}_${dateKey}_$normalizedTitle';
  }
}
