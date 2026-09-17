import 'package:flutter_test/flutter_test.dart';

import 'package:jersey_checker/main.dart';

void main() {
  testWidgets('studio opens on the 3D tester tab', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('3D Player Preview'), findsOneWidget);
    expect(find.text('Select Jersey PNG'), findsOneWidget);
    expect(find.text('PNG to .bytes Converter'), findsNothing);
  });

  testWidgets('converter tab shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Converter'));
    await tester.pumpAndSettle();

    expect(find.text('PNG to .bytes Converter'), findsOneWidget);
    expect(find.text('No PNG files selected'), findsOneWidget);
  });
}
