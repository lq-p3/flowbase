import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowbase/core/theme.dart';
import 'package:flowbase/data/models.dart';
import 'package:flowbase/main.dart';
import 'package:flowbase/screens/main_shell.dart';
import 'package:flowbase/widgets/bottom_nav.dart';
import 'package:flowbase/state/app_state.dart';

void main() {
  test('mock data stays consistent', () {
    final app = AppState();
    expect(app.activeIn('work'), 12);
    expect(app.activeIn('study'), 8);
    expect(app.activeIn('personal'), 5);
    expect(app.activeIn('health'), 3);
    expect(app.stats('q4').percent, 80);
    expect(app.stats('ai').percent, 40);
  });

  test('completing a task updates project progress', () {
    final app = AppState();
    final before = app.stats('ai').done;
    expect(app.toggleTask('t33'), isTrue);
    expect(app.stats('ai').done, before + 1);
    expect(app.task('t33')!.status, TaskStatus.done);
  });

  testWidgets('onboarding renders', (tester) async {
    await tester.pumpWidget(FlowBaseApp(state: AppState()));
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
  });
  testWidgets('bottom nav keeps its height on a phone screen', (tester) async {
    _phoneSize(tester);
    final state = AppState();
    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(theme: buildTheme(Brightness.light, false), home: const MainShell()),
    ));
    await tester.pump(const Duration(seconds: 1));
    final height = tester.getSize(find.byType(FbBottomNav)).height;
    expect(height, lessThan(120));
  });
}

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 186, bottom: 102);
  addTearDown(tester.view.reset);
}
