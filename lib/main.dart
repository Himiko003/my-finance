import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/dashboard.dart';
import 'services/transaction_service.dart';
import 'services/budget_service.dart';
import 'services/category_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load semua data yang tersimpan
  await TransactionService.loadTransactions();
  await BudgetService.loadBudgets();
  await CategoryService.loadCategories();
  await NotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('dark_mode') ?? false;

  runApp(
    MyFinanceApp(initialDarkMode: isDarkMode),
  );
}

class MyFinanceApp extends StatefulWidget {
  final bool initialDarkMode;

  const MyFinanceApp({
    super.key,
    this.initialDarkMode = false,
  });

  @override
  State<MyFinanceApp> createState() => _MyFinanceAppState();
}

class _MyFinanceAppState extends State<MyFinanceApp> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
  }

  Future<void> toggleTheme() async {
    setState(() {
      isDarkMode = !isDarkMode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Finance',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F1EA),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF172033),
          brightness: Brightness.light,
          primary: const Color(0xFF172033),
          secondary: const Color(0xFFE8B85C),
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1522),
        cardColor: const Color(0xFF182131),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8B85C),
          brightness: Brightness.dark,
          primary: const Color(0xFFE8B85C),
          secondary: const Color(0xFFE8B85C),
          surface: const Color(0xFF182131),
        ),
      ),
      home: Dashboard(
        onToggleTheme: toggleTheme,
        isDarkMode: isDarkMode,
      ),
    );
  }
}