import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/comparison_engine.dart';
import 'package:price_compare_flutter/engine/unit.dart';
import 'package:price_compare_flutter/providers/price_compare_provider.dart';

void main() {
  test('入力更新から比較結果まで状態が遷移する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(priceCompareProvider.notifier);
    notifier.updateInputA(
      const ProductInput(
        displayedPrice: '1000',
        taxRatePercent: '10',
        quantity: '500',
        unit: ComparisonUnit.gram,
      ),
    );
    notifier.updateInputB(
      const ProductInput(
        displayedPrice: '1200',
        taxRatePercent: '10',
        quantity: '600',
        unit: ComparisonUnit.gram,
      ),
    );

    expect(container.read(priceCompareProvider).result, isNull);
    expect(notifier.compare(), isTrue);

    final state = container.read(priceCompareProvider);
    expect(state.errorMessage, isNull);
    expect(state.result, isNotNull);
    expect(
      state.result?.cheapestByPayable,
      ComparisonWinner.productA,
    );
    expect(
      state.result?.cheapestByUnitPrice,
      ComparisonWinner.tie,
    );
  });
}
