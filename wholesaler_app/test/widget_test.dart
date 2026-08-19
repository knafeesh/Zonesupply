import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wholesaler_app/main.dart';
import 'package:wholesaler_app/providers/auth_provider.dart';

void main() {
  testWidgets('WholesalerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
        child: const WholesalerApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
