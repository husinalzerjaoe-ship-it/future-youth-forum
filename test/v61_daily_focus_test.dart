import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/v61_daily_focus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('daily focus opens with a useful empty state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: V61DailyFocusPage()));
    await tester.pumpAndSettle();

    expect(find.text('ما عندك أهداف مضافة بعد'), findsOneWidget);
    expect(find.text('هدف جديد'), findsOneWidget);
  });

  testWidgets('a new goal can be added and completed', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: V61DailyFocusPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('هدف جديد'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'أقرأ عشرة صفحات');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.text('أقرأ عشرة صفحات'), findsOneWidget);
    expect(find.text('أنجزت 0 من 1 أهداف اليوم'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.text('أنجزت 1 من 1 أهداف اليوم'), findsOneWidget);
    expect(find.text('تم الإنجاز'), findsOneWidget);
  });

  testWidgets('daily goals persist locally between page instances', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: V61DailyFocusPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('هدف جديد'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'أراجع دروسي');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('صفحة أخرى'))));
    await tester.pumpWidget(const MaterialApp(home: V61DailyFocusPage()));
    await tester.pumpAndSettle();

    expect(find.text('أراجع دروسي'), findsOneWidget);
  });
}
