import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/unit.dart';
import 'package:price_compare_flutter/providers/price_compare_provider.dart';

void main() {
  ProductInput product(String price) => ProductInput(
        displayedPrice: price,
        taxRatePercent: '10',
        quantity: '1',
        unit: ComparisonUnit.count,
      );

  test('商品Aと商品Bに別々の送料・クーポン・ポイントを適用する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(priceCompareProvider.notifier);

    notifier.updateInputA(product('1000'));
    notifier.updateInputB(product('1200'));
    notifier.updateContextA(
      const PurchaseContextInput(
        shippingCost: '500',
        couponAmount: '100',
        usedPoints: '50',
        earnedPoints: '25',
      ),
    );
    notifier.updateContextB(
      const PurchaseContextInput(
        shippingCost: '0',
        earnedPoints: '100',
      ),
    );

    expect(notifier.compare(), isTrue);
    final result = container.read(priceCompareProvider).result!;
    expect(result.breakdownA.shippingCost!.amount.toPlainString(), '500');
    expect(result.breakdownA.totalCouponDiscount.amount.toPlainString(), '100');
    expect(result.breakdownA.payableNow.amount.toPlainString(), '1350');
    expect(result.breakdownA.effectiveCost.amount.toPlainString(), '1325');
    expect(result.breakdownB.shippingCost!.amount.toPlainString(), '0');
    expect(result.breakdownB.totalCouponDiscount.amount.toPlainString(), '0');
    expect(result.breakdownB.payableNow.amount.toPlainString(), '1200');
    expect(result.breakdownB.effectiveCost.amount.toPlainString(), '1100');
  });

  test('旧共通更新APIは互換性のため両方の購入条件を更新する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(priceCompareProvider.notifier);

    notifier.updateShippingCost('300');
    notifier.updateCouponAmount('50');

    final state = container.read(priceCompareProvider);
    expect(state.contextA.shippingCost, '300');
    expect(state.contextB.shippingCost, '300');
    expect(state.contextA.couponAmount, '50');
    expect(state.contextB.couponAmount, '50');
    expect(state.shippingCost, '300');
    expect(state.couponAmount, '50');
  });
}
