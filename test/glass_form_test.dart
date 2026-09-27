import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/glass/glass_dialog.dart';
import 'package:huike_timetable/core/glass/glass_form.dart';

void main() {
  testWidgets('玻璃文本框保留原生输入与 onChanged 行为', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: GlassTextField(
              controller: controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: '教务网址'),
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'https://jw.example.edu.cn');
    expect(controller.text, 'https://jw.example.edu.cn');
    expect(changed, 'https://jw.example.edu.cn');
    expect(tester.takeException(), isNull);
  });

  testWidgets('玻璃单选项与勾选项可操作并暴露状态', (tester) async {
    var selected = '跟随系统';
    var checked = false;
    var section = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                GlassSelectionRow(
                  label: '跟随系统',
                  selected: selected == '跟随系统',
                  onSelected: () => setState(() => selected = '跟随系统'),
                ),
                GlassSelectionRow(
                  label: '夜间',
                  selected: selected == '夜间',
                  onSelected: () => setState(() => selected = '夜间'),
                ),
                GlassToggleRow(
                  label: '替换作息时间',
                  value: checked,
                  onChanged: (value) => setState(() => checked = value),
                ),
                GlassPickerRow<int>(
                  label: '节次',
                  value: section,
                  options: const [(1, '第1节'), (2, '第2节')],
                  onChanged: (value) => setState(() => section = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('夜间'));
    await tester.pumpAndSettle();
    expect(selected, '夜间');
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any(
            (semantics) =>
                semantics.properties.label == '夜间' &&
                semantics.properties.selected == true,
          ),
      isTrue,
    );

    await tester.tap(find.text('替换作息时间'));
    await tester.pumpAndSettle();
    expect(checked, isTrue);

    await tester.tap(find.byType(GlassPickerRow<int>));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);
    await tester.tap(find.text('第2节'));
    await tester.pumpAndSettle();
    expect(section, 2);
  });

  testWidgets('破坏性操作使用共享玻璃确认框且 1.3 倍字号可布局', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showGlassDialog<void>(
                  context: context,
                  builder: (dialogContext) => GlassDialog(
                    title: const Text('删除课程'),
                    content: const Text('此操作不可撤销。'),
                    actions: [
                      GlassDialogAction(
                        label: '取消',
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                      GlassDialogAction(
                        label: '删除',
                        destructive: true,
                        onPressed: () {
                          confirmed = true;
                          Navigator.pop(dialogContext);
                        },
                      ),
                    ],
                  ),
                ),
                child: const Text('打开确认框'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开确认框'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);
    expect(find.text('此操作不可撤销。'), findsOneWidget);
    expect(tester.getRect(find.text('删除')).bottom, lessThanOrEqualTo(844));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
    expect(find.byType(GlassDialog), findsNothing);
  });
}
