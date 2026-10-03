import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/core/glass/glass_dialog.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';

void main() {
  late AppDatabase db;
  late String schoolId;
  const originalUrl = 'https://old.example.edu.cn/login';

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> openPage(WidgetTester tester) async {
    final repository = SchoolRepository(db);
    final school = await repository.createSchool(
      displayName: '网址测试大学',
      adapterId: 'auto',
      loginUrl: originalUrl,
      confirmedHosts: const ['old.example.edu.cn'],
    );
    schoolId = school.id;
    await repository.createSemester(
      schoolId: schoolId,
      firstWeekMonday: DateTime(2026, 8, 31),
      totalWeeks: 20,
    );
    await repository.setActiveSchool(schoolId);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        adapterCatalogProvider.overrideWith(
          (ref) async => const AdapterCatalog(entries: []),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HuikeApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('学校管理、切换与导入配置'));
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改教务网址'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  Future<void> checkClosed(WidgetTester tester) async {
    // Exercise focus/field rebuild while the popped route is still animating.
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(GlassDialog), findsNothing);
    expect(find.text('学校管理'), findsOneWidget);
  }

  Future<void> expectStored(String url, List<String> hosts) async {
    final row = await (db.select(
      db.schools,
    )..where((t) => t.id.equals(schoolId))).getSingle();
    expect(row.loginUrl, url);
    expect(jsonDecode(row.acceptedHostsJson), hosts);
  }

  testWidgets('取消编辑不报错且不写入；可再次打开输入', (tester) async {
    await openPage(tester);
    for (var i = 0; i < 2; i++) {
      await openDialog(tester);
      await tester.enterText(
        find.byType(TextField),
        'https://new.example.edu.cn',
      );
      await tester.tap(find.text('取消'));
      await checkClosed(tester);
      await expectStored(originalUrl, ['old.example.edu.cn']);
    }
  });

  for (final scheme in ['https', 'http']) {
    testWidgets('保存 $scheme 地址正常关闭并更新地址与主机', (tester) async {
      await openPage(tester);
      await openDialog(tester);
      final url = '$scheme://new.example.edu.cn/login';
      await tester.enterText(find.byType(TextField), url);
      await tester.tap(find.text('保存'));
      await checkClosed(tester);
      await expectStored(url, ['old.example.edu.cn', 'new.example.edu.cn']);
      expect(find.text('教务网址已更新'), findsOneWidget);
    });
  }

  for (final value in ['', 'javascript:alert(1)']) {
    testWidgets('保存无效地址 "$value" 不报错且不写入', (tester) async {
      await openPage(tester);
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), value);
      await tester.tap(find.text('保存'));
      await checkClosed(tester);
      await expectStored(originalUrl, ['old.example.edu.cn']);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('教务网址已更新'), findsNothing);
    });
  }

  testWidgets('点击遮罩与系统返回关闭均不报错且不写入', (tester) async {
    await openPage(tester);
    await openDialog(tester);
    await tester.enterText(
      find.byType(TextField),
      'https://new.example.edu.cn',
    );
    await tester.tapAt(const Offset(10, 100));
    await checkClosed(tester);
    await openDialog(tester);
    await tester.enterText(
      find.byType(TextField),
      'https://new.example.edu.cn',
    );
    await tester.binding.handlePopRoute();
    await checkClosed(tester);
    await expectStored(originalUrl, ['old.example.edu.cn']);
  });
}
