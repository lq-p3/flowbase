import 'package:flutter_test/flutter_test.dart';

import 'package:flowbase/data/models.dart';
import 'package:flowbase/main.dart';
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
}
