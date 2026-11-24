import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/v65_post_drafts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('V65 creates and persists an offline post draft', (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: V65PostDraftsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إنشاء أول مسودة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'عنوان المسودة'), 'فكرة جديدة');
    await tester.enterText(find.widgetWithText(TextField, 'محتوى المنشور'), 'هذا نص تجريبي للمسودة');
    await tester.tap(find.text('حفظ المسودة'));
    await tester.pumpAndSettle();

    expect(find.text('فكرة جديدة'), findsOneWidget);
    expect(find.text('هذا نص تجريبي للمسودة'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: V65PostDraftsPage()));
    await tester.pumpAndSettle();

    expect(find.text('فكرة جديدة'), findsOneWidget);
    expect(find.text('هذا نص تجريبي للمسودة'), findsOneWidget);
  });

  testWidgets('V65 duplicates a draft without changing the original', (tester) async {
    SharedPreferences.setMockInitialValues({
      'v65_offline_post_drafts': '[{"id":"1","title":"رحلة","body":"السفر إلى البصرة","updatedAt":"2026-11-20T10:00:00"}]',
    });
    await tester.pumpWidget(const MaterialApp(home: V65PostDraftsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('نسخ كمسودة'));
    await tester.pumpAndSettle();
    expect(find.text('رحلة'), findsOneWidget);
    expect(find.text('نسخة من رحلة'), findsOneWidget);
    expect(find.text('المسودات المحفوظة: 2'), findsOneWidget);
  });

  testWidgets('V65 filters drafts by their content', (tester) async {
    SharedPreferences.setMockInitialValues({
      'v65_offline_post_drafts': '[{"id":"1","title":"رحلة","body":"السفر إلى البصرة","updatedAt":"2026-11-20T10:00:00"}]',
    });
    await tester.pumpWidget(const MaterialApp(home: V65PostDraftsPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'البصرة');
    await tester.pumpAndSettle();
    expect(find.text('رحلة'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'غير موجود');
    await tester.pumpAndSettle();
    expect(find.text('ما لقينا مسودات تطابق البحث.'), findsOneWidget);
  });
}
