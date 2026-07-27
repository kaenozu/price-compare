import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/decimal.dart';
import 'package:price_compare_flutter/engine/money.dart';
import 'package:price_compare_flutter/engine/offer.dart';
import 'package:price_compare_flutter/engine/price_calculator.dart';
import 'package:price_compare_flutter/engine/purchase_context.dart';
import 'package:price_compare_flutter/engine/quantity.dart';
import 'package:price_compare_flutter/engine/tax_mode.dart';
import 'package:price_compare_flutter/engine/unit.dart';

void main() {
  group('PriceCalculator', () {
    test('税・割引・クーポン・送料・ポイントを順番に適用する', () {
      final offer = Offer(
        productName: '商品A',
        displayedPrice: Money.of('1000'),
        taxMode: TaxMode.taxIncluded,
        taxRate: Decimal('0.1'),
        quantity: Quantity(value: Decimal('500'), unit: ComparisonUnit.gram),
        discounts: [PercentageDiscount(Decimal('0.1'))],
      );
      final context = PurchaseContext(
        shippingCost: Money.of('50'),
        orderCoupons: [CouponDiscount(Money.of('100'))],
        usedPoints: 20,
        earnedPoints: 30,
      );

      final result = PriceCalculator.calculate(offer, context);

      expect(result.totalItemDiscount.amount.toPlainString(), '100');
      expect(result.totalCouponDiscount.amount.toPlainString(), '100');
      expect(result.payableNow.amount.toPlainString(), '830');
      expect(result.effectiveCost.amount.toPlainString(), '800');
      expect(result.unitPrice?.toPlainString(), '160');
    });

    test('送料無料条件はクーポン適用後・ポイント使用前に判定する', () {
      final offer = Offer(
        productName: '商品A',
        displayedPrice: Money.of('3000'),
        taxMode: TaxMode.taxIncluded,
        taxRate: Decimal('0.1'),
        quantity: Quantity(value: Decimal('1'), unit: ComparisonUnit.count),
      );
      final context = PurchaseContext(
        shippingCost: Money.of('500'),
        freeShippingThreshold: Money.of('3000'),
        usedPoints: 100,
      );

      final result = PriceCalculator.calculate(offer, context);

      expect(result.shippingCost, Money.zero);
      expect(result.payableNow.amount.toPlainString(), '2900');
    });
  });
}
