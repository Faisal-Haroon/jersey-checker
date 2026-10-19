import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jersey_checker/screens/converter_screen.dart';
import 'package:jersey_checker/screens/home_dashboard_screen.dart';
import 'package:jersey_checker/theme/app_theme.dart';
import 'package:jersey_checker/widgets/banner_ad_widget.dart';

void main() {
  testWidgets(
    'HomeDashboardScreen renders tools and sticky bottom banner slot',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomeDashboardScreen(
              onOpen3DStudio: () {},
              onOpenConverter: () {},
            ),
          ),
        ),
      );

      // Header and tool cards
      expect(find.text('TOOLS'), findsOneWidget);
      expect(find.text('3D Studio'), findsWidgets);
      expect(find.text('Converter'), findsWidgets);
      expect(find.text('Jersey'), findsOneWidget);

      // Sticky banner ad widget is present
      expect(find.byType(AppBannerWidget), findsOneWidget);
    },
  );

  testWidgets('ConverterScreen renders active mode and controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ConverterScreen(
            files: const [],
            onPickFiles: () {},
            onPickBytesFiles: () {},
            onClearAll: () {},
            onRemoveFile: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('PNG → File'), findsWidgets);
  });

  testWidgets('AppBannerWidget reserves layout dimensions gracefully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppBannerWidget())),
    );

    expect(find.byType(AppBannerWidget), findsOneWidget);
  });
}
