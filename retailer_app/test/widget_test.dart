import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:retailer_app/main.dart';
import 'package:retailer_app/providers/auth_provider.dart';
import 'package:retailer_app/providers/cart_provider.dart';

void main() {
  testWidgets('ZoneStoreApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const ZoneStoreApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
