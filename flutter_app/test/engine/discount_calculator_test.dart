import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/decimal.dart';
import 'package:price_compare_flutter/engine/discount_calculator.dart';
import 'package:price_compare_flutter/engine/money.dart';
import 'package:price_compare_flutter/engine/offer.dart';

void main() {
  group('DiscountCalculator', () {
    group('applyItemDiscounts', () {
      test('割引なしの場合は金額が変わらない', () {
        final result = DiscountCalculator.applyItemDiscounts(
          Money.of('1000'),
          [],
        );
        expect(result.discountedAmount, Money.of('1000'));
        expect(result.totalDiscount, Money.zero);
      });

      test('固定額割引を適用する', () {
        final result = DiscountCalculator.applyItemDiscounts(
          Money.of('1000'),
          [FixedAmountDiscount(Money.of('200'))],
        );
        expect(result.discountedAmount, Money.of('800'));
        expect(result.totalDiscount, Money.of('200'));
      });

      test('パーセント割引を適用する', () {
        final result = DiscountCalculator.applyItemDiscounts(
          Money.of('1000'),
          [PercentageDiscount(Decimal('0.1'))],
        );
        expect(result.discountedAmount, Money.of('900'));
        expect(result.totalDiscount, Money.of('100'));
      });

      test('複数の割引を順番に適用する', () {
        final result = DiscountCalculator.applyItemDiscounts(
          Money.of('1000'),
          [
            FixedAmountDiscount(Money.of('200')),
            PercentageDiscount(Decimal('0.1')),
          ],
        );
        expect(result.discountedAmount, Money.of('720'));
        expect(result.totalDiscount, Money.of('280'));
      });
    });

    group('applyCoupons', () {
      test('クーポンなしの場合は金額が変わらない', () {
        final result = DiscountCalculator.applyCoupons(Money.of('1000'), []);
        expect(result.discountedAmount, Money.of('1000'));
        expect(result.totalDiscount, Money.zero);
      });

      test('単一クーポンを適用する', () {
        final result = DiscountCalculator.applyCoupons(
          Money.of('1000'),
          [CouponDiscount(Money.of('300'))],
        );
        expect(result.discountedAmount, Money.of('700'));
        expect(result.totalDiscount, Money.of('300'));
      });

      test('複数クーポンを順番に適用する', () {
        final result = DiscountCalculator.applyCoupons(
          Money.of('1000'),
          [
            CouponDiscount(Money.of('200'), name: '新学期セール'),
            CouponDiscount(Money.of('100'), name: '初回クーポン'),
          ],
        );
        expect(result.discountedAmount, Money.of('700'));
        expect(result.totalDiscount, Money.of('300'));
      });
    });
  });
}
