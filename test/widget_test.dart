import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_flutter/main.dart';
import 'package:test_flutter/services/transaction_service.dart';
import 'package:test_flutter/services/budget_service.dart';
import 'package:test_flutter/services/category_service.dart';
import 'package:test_flutter/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TransactionService.loadTransactions();
    await BudgetService.loadBudgets();
    await CategoryService.loadCategories();
    NotificationService.resetForTesting();
  });

  testWidgets('MyFinanceApp smoke test & dashboard renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyFinanceApp());
    await tester.pumpAndSettle();

    // Verify app title and greeting render
    expect(find.text('MyFinance'), findsOneWidget);
    expect(find.text('Halo, Bro 👋'), findsOneWidget);
    expect(find.text('TOTAL SALDO'), findsOneWidget);
    expect(find.text('Akses Cepat'), findsOneWidget);

    // Verify notification icon is present in AppBar
    expect(find.byTooltip('Auto Detect Transaksi'), findsOneWidget);

    // Verify theme toggle icon exists
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });
}
