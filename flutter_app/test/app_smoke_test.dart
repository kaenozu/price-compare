import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/main.dart';

void main() {
  testWidgets('価格比較フォームを表示し、必須入力を検証できる', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PriceCompareApp(),
      ),
    );

    expect(find.text('商品A'), findsOneWidget);
    expect(find.text('商品B'), findsOneWidget);
    expect(find.text('比較する'), findsOneWidget);

    await tester.tap(find.text('比較する'));
    await tester.pump();

    expect(find.text('表示価格を入力してください'), findsNWidgets(2));
    expect(find.text('数量を入力してください'), findsNWidgets(2));
    expect(find.byType(SnackBar), findsNothing);
  });
}
