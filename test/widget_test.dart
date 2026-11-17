import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_scorekeeper/main.dart';

void main() {
  testWidgets('shows the player setup screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const LettercountApp());

    expect(find.text('Who\'s playing?'), findsOneWidget);
    expect(find.text('Start a new game'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
