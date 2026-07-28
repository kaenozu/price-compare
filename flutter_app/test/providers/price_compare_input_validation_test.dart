import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/unit.dart';
import 'package:price_compare_flutter/providers/price_compare_provider.dart';

void main() {
  ProductInput validProduct({
    String price = '1000',
    String discount = '',
    bool discountIsPercent = false,
  }) =>
      ProductInput(
        displayedPrice: price,
        taxRatePercent: '10',
        quantity: '1',
        unit: ComparisonUnit.count,
        discountValue: discount,
        discountIsPercent: discountIsPercent,
      );

  PriceCompareNotifier notifierWithValidProducts(ProviderContainer container) {
    final notifier = container.read(priceCompareProvider.notifier);
    notifier.updateInputA(validProduct());
    notifier.updateInputB(validProduct(price: '1200'));
    return notifier;
  }

  test('使用ポイントは負数を拒否する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = notifierWithValidProducts(container);

    notifier.updateUsedPoints('-1');

    expect(notifier.compare(), isFalse);
    expect(
      container.read(priceCompareProvider).errorMessage,
      '使用ポイントは0以上の整数で入力してください',
    );
  });

  test('獲得ポイントは小数を拒否する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = notifierWithValidProducts(container);

    notifier.updateEarnedPoints('1.5');

    expect(notifier.compare(), isFalse);
    expect(
      container.read(priceCompareProvider).errorMessage,
      '獲得ポイントは0以上の整数で入力してください',
    );
  });

  test('整数範囲を超えるポイント入力を拒否する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = notifierWithValidProducts(container);

    notifier.updateUsedPoints('999999999999999999999999999999999999');

    expect(notifier.compare(), isFalse);
    expect(
      container.read(priceCompareProvider).errorMessage,
      '使用ポイントは0以上の整数で入力してください',
    );
  });

  test('空白を含む使用・獲得ポイントを同時に適用できる', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = notifierWithValidProducts(container);

    notifier.updateUsedPoints(' 100 ');
    notifier.updateEarnedPoints(' 20 ');

    expect(notifier.compare(), isTrue);
    final result = container.read(priceCompareProvider).result!;
    expect(result.breakdownA.pointRedemption.amount.toPlainString(), '100');
    expect(result.breakdownA.earnedPointsValue.amount.toPlainString(), '20');
  });

  test('0ポイントは有効な入力として扱う', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = notifierWithValidProducts(container);

    notifier.updateUsedPoints('0');
    notifier.updateEarnedPoints('0');

    expect(notifier.compare(), isTrue);
    expect(container.read(priceCompareProvider).errorMessage, isNull);
  });

  test('負の送料を拒否する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = notifierWithValidProducts(container);

    notifier.updateShippingCost('-100');

    expect(notifier.compare(), isFalse);
    expect(
      container.read(priceCompareProvider).errorMessage,
      '送料は0以上で入力してください',
    );
  });

  test('負のクーポン額を拒否する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = notifierWithValidProducts(container);

    notifier.updateCouponAmount('-100');

    expect(notifier.compare(), isFalse);
    expect(
      container.read(priceCompareProvider).errorMessage,
      'クーポンは0以上で入力してください',
    );
  });

  test('負の定額割引を拒否する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(priceCompareProvider.notifier);
    notifier.updateInputA(validProduct(discount: '-10'));
    notifier.updateInputB(validProduct(price: '1200'));

    expect(notifier.compare(), isFalse);
    expect(
      container.read(priceCompareProvider).errorMessage,
      '割引額は0以上で入力してください',
    );
  });

  test('100%を超える割合割引を拒否する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(priceCompareProvider.notifier);
    notifier.updateInputA(
      validProduct(discount: '100.1', discountIsPercent: true),
    );
    notifier.updateInputB(validProduct(price: '1200'));

    expect(notifier.compare(), isFalse);
    expect(
      container.read(priceCompareProvider).errorMessage,
      '割引率は0〜100%で入力してください',
    );
  });
}
