import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/v64_personal_toolbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('V64 toolbox opens with local journal and tools', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: V64PersonalToolboxPage()));
    await tester.pumpAndSettle();

    expect(find.text('صندوق أدوات V64'), findsOneWidget);
    expect(find.text('يومياتي الخاصة'), findsOneWidget);
    expect(find.text('ساعة الإيقاف'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('مؤقت تنازلي'), 240);
    expect(find.text('مؤقت تنازلي'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('مختبر النصوص'), 240);
    expect(find.text('مختبر النصوص'), findsOneWidget);
  });

  testWidgets('private journal entry persists locally between page instances', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: V64PersonalToolboxPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'إضافة').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'هذه يومياتي الخاصة');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('هذه يومياتي الخاصة'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: V64PersonalToolboxPage()));
    await tester.pumpAndSettle();

    expect(find.text('هذه يومياتي الخاصة'), findsOneWidget);
  });

  testWidgets('stopwatch starts and can be reset', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: V64PersonalToolboxPage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('ابدأ'));
    await tester.tap(find.text('ابدأ'));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.ensureVisible(find.byKey(const ValueKey('v64-stopwatch-time')));
    await tester.pump();
    final elapsed = tester.widget<Text>(find.byKey(const ValueKey('v64-stopwatch-time'))).data!;
    expect(elapsed, isNot('00:00:00.0'));

    await tester.ensureVisible(find.text('إعادة'));
    await tester.tap(find.text('إعادة'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const ValueKey('v64-stopwatch-time'))).data, '00:00:00.0');
  });
}
