import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app/main.dart';
import 'package:delivery_app/providers/auth_provider.dart';

void main() {
  testWidgets('DeliveryApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
        child: const DeliveryApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
