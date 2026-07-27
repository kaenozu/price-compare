import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/decimal.dart';
import 'package:price_compare_flutter/engine/money.dart';
import 'package:price_compare_flutter/engine/purchase_context.dart';

void main() {
  group('PurchaseContext', () {
    group('コンストラクタ', () {
      test('デフォルト値で生成する', () {
        final context = PurchaseContext();
        expect(context.shippingCost, isNull);
        expect(context.freeShippingThreshold, isNull);
        expect(context.orderCoupons, isEmpty);
        expect(context.usedPoints, 0);
        expect(context.earnedPoints, 0);
        expect(context.pointEvaluationRate, Decimal.one);
      });

      test('負のポイントで例外を投げる', () {
        expect(() => PurchaseContext(usedPoints: -1), throwsArgumentError);
        expect(() => PurchaseContext(earnedPoints: -1), throwsArgumentError);
      });

      test('pointEvaluationRateが範囲外で例外を投げる', () {
        expect(
          () => PurchaseContext(pointEvaluationRate: Decimal('-0.1')),
          throwsArgumentError,
        );
        expect(
          () => PurchaseContext(pointEvaluationRate: Decimal('2.1')),
          throwsArgumentError,
        );
      });
    });

    group('isShippingFree', () {
      test('freeShippingThresholdがnullの場合は無料にならない', () {
        final context = PurchaseContext(shippingCost: Money.of('500'));
        expect(context.isShippingFree(Money.of('10000')), isFalse);
      });

      test('金額がしきい値以上の場合は送料無料', () {
        final context = PurchaseContext(
          shippingCost: Money.of('500'),
          freeShippingThreshold: Money.of('3000'),
        );
        expect(context.isShippingFree(Money.of('3000')), isTrue);
        expect(context.isShippingFree(Money.of('5000')), isTrue);
      });

      test('金額がしきい値未満の場合は送料無料にならない', () {
        final context = PurchaseContext(
          shippingCost: Money.of('500'),
          freeShippingThreshold: Money.of('3000'),
        );
        expect(context.isShippingFree(Money.of('2999')), isFalse);
      });
    });

    group('effectiveShipping', () {
      test('shippingCostがnullの場合はnullを返す', () {
        final context = PurchaseContext(freeShippingThreshold: Money.of('3000'));
        expect(context.effectiveShipping(Money.of('5000')), isNull);
      });

      test('送料無料条件を満たすと送料が0になる', () {
        final context = PurchaseContext(
          shippingCost: Money.of('500'),
          freeShippingThreshold: Money.of('3000'),
        );
        expect(context.effectiveShipping(Money.of('5000')), Money.zero);
      });

      test('送料無料条件を満たさないと送料がそのままかかる', () {
        final context = PurchaseContext(
          shippingCost: Money.of('500'),
          freeShippingThreshold: Money.of('3000'),
        );
        expect(context.effectiveShipping(Money.of('2000')), Money.of('500'));
      });

      test('しきい値がない場合は常に送料がかかる', () {
        final context = PurchaseContext(shippingCost: Money.of('500'));
        expect(context.effectiveShipping(Money.of('10000')), Money.of('500'));
      });
    });

    group('ポイント価値', () {
      test('獲得ポイントの価値を計算する', () {
        final context = PurchaseContext(
          earnedPoints: 100,
          pointEvaluationRate: Decimal('0.01'),
        );
        expect(context.earnedPointsValue(), Money.of('1'));
      });

      test('使用ポイントの価値を計算する', () {
        final context = PurchaseContext(
          usedPoints: 500,
          pointEvaluationRate: Decimal('0.01'),
        );
        expect(context.usedPointsValue(), Money.of('5'));
      });

      test('ポイント評価レートのデフォルトは1倍', () {
        final context = PurchaseContext(earnedPoints: 200);
        expect(context.earnedPointsValue(), Money.of('200'));
      });
    });
  });
}
