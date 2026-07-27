import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/decimal.dart';
import 'package:price_compare_flutter/engine/money.dart';
import 'package:price_compare_flutter/engine/quantity.dart';
import 'package:price_compare_flutter/engine/unit.dart';
import 'package:price_compare_flutter/engine/unit_normalizer.dart';

void main() {
  group('UnitNormalizer', () {
    group('areComparable', () {
      test('同じ次元の単位は比較可能', () {
        final a = Quantity(value: Decimal('500'), unit: ComparisonUnit.gram);
        final b = Quantity(value: Decimal('1'), unit: ComparisonUnit.kilogram);
        expect(UnitNormalizer.areComparable(a, b), isTrue);
      });

      test('異なる次元の単位は比較不可', () {
        final a = Quantity(value: Decimal('500'), unit: ComparisonUnit.gram);
        final b = Quantity(value: Decimal('500'), unit: ComparisonUnit.milliliter);
        expect(UnitNormalizer.areComparable(a, b), isFalse);
      });
    });

    group('calculateUnitPrice', () {
      test('100gあたりの単価を計算する（g）', () {
        final price = UnitNormalizer.calculateUnitPrice(
          price: Money.of('500'),
          quantity: Quantity(value: Decimal('200'), unit: ComparisonUnit.gram),
        );
        expect(price?.toPlainString(), '250');
      });

      test('100gあたりの単価を計算する（kg→g変換）', () {
        final price = UnitNormalizer.calculateUnitPrice(
          price: Money.of('1000'),
          quantity: Quantity(value: Decimal('2'), unit: ComparisonUnit.kilogram),
        );
        expect(price?.toPlainString(), '50');
      });

      test('100mLあたりの単価を計算する（L→mL変換）', () {
        final price = UnitNormalizer.calculateUnitPrice(
          price: Money.of('300'),
          quantity: Quantity(value: Decimal('1.5'), unit: ComparisonUnit.liter),
        );
        expect(price?.toPlainString(), '20');
      });

      test('数量が0の場合はnullを返す', () {
        final price = UnitNormalizer.calculateUnitPrice(
          price: Money.of('500'),
          quantity: Quantity(value: Decimal.zero, unit: ComparisonUnit.gram),
        );
        expect(price, isNull);
      });
    });

    group('normalizeQuantity', () {
      test('キログラムをグラムに正規化する', () {
        final normalized = UnitNormalizer.normalizeQuantity(
          Quantity(value: Decimal('1.5'), unit: ComparisonUnit.kilogram),
        );
        expect(normalized.value.toPlainString(), '1500');
        expect(normalized.unit, ComparisonUnit.gram);
      });
    });
  });
}
