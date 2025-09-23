import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DokiDoki/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock SharedPreferences agar SettingsProvider bisa load tanpa platform channel
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots and shows Home UI', (WidgetTester tester) async {
    await tester.pumpWidget(const DokiDokiApp());
    await tester.pumpAndSettle();

    // Ada judul app dan ikon Home di bottom nav
    expect(find.text('DokiDoki'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    // Ada ikon Search di AppBar
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });
}
