import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/comparison_engine.dart';
import 'package:price_compare_flutter/engine/decimal.dart';
import 'package:price_compare_flutter/engine/money.dart';
import 'package:price_compare_flutter/engine/offer.dart';
import 'package:price_compare_flutter/engine/purchase_context.dart';
import 'package:price_compare_flutter/engine/quantity.dart';
import 'package:price_compare_flutter/engine/tax_mode.dart';
import 'package:price_compare_flutter/engine/unit.dart';

void main() {
  final context = PurchaseContext(shippingCost: Money.zero);

  Offer offer({
    required String name,
    required String price,
    required String quantity,
    required ComparisonUnit unit,
  }) =>
      Offer(
        productName: name,
        displayedPrice: Money.of(price),
        taxMode: TaxMode.taxIncluded,
        taxRate: Decimal('0.1'),
        quantity: Quantity(
          value: Decimal(quantity),
          unit: unit,
        ),
      );

  group('ComparisonEngine', () {
    test('kgとgを正規化して最安商品を判定する', () {
      final result = ComparisonEngine.compare(
        offerA: offer(
          name: '商品A',
          price: '500',
          quantity: '0.5',
          unit: ComparisonUnit.kilogram,
        ),
        contextA: context,
        offerB: offer(
          name: '商品B',
          price: '600',
          quantity: '500',
          unit: ComparisonUnit.gram,
        ),
        contextB: context,
      );

      expect(result.isComparable, isTrue);
      expect(result.cheapestByPayable, ComparisonWinner.productA);
      expect(result.cheapestByUnitPrice, ComparisonWinner.productA);
      expect(result.payableDifference.amount.toPlainString(), '100');
    });

    test('重量と容量は比較不能理由を返す', () {
      final result = ComparisonEngine.compare(
        offerA: offer(
          name: '商品A',
          price: '500',
          quantity: '500',
          unit: ComparisonUnit.gram,
        ),
        contextA: context,
        offerB: offer(
          name: '商品B',
          price: '500',
          quantity: '500',
          unit: ComparisonUnit.milliliter,
        ),
        contextB: context,
      );

      expect(result.isComparable, isFalse);
      expect(result.incompatibilityReason, isNotNull);
      expect(result.cheapestByUnitPrice, isNull);
    });
  });
}
