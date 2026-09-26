import 'package:flutter/material.dart';

import 'screens/dashboard.dart';
import 'services/transaction_service.dart';
import 'services/budget_service.dart';
import 'services/category_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load semua data yang tersimpan
  await TransactionService
      .loadTransactions();

  await BudgetService
      .loadBudgets();

  await CategoryService
      .loadCategories();

  runApp(
    const MyFinanceApp(),
  );
}

class MyFinanceApp
    extends StatelessWidget {
  const MyFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Finance',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed:
            Colors.blue,
        scaffoldBackgroundColor:
            const Color(0xFFF5F7FA),
      ),
      home:
          const Dashboard(),
    );
  }
}