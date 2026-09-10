import 'package:finguruz/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('FinGuruz App loads and displays Dashboard bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(const FinGuruzApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });
}
