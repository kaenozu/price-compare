import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/decimal.dart';
import 'package:price_compare_flutter/engine/quantity.dart';
import 'package:price_compare_flutter/engine/unit.dart';

void main() {
  group('Quantity', () {
    test('toStringが正しい形式で表示する', () {
      final q = Quantity(value: Decimal('500'), unit: ComparisonUnit.gram);
      expect(q.toString(), '500g');
    });

    group('normalize', () {
      test('グラムはそのまま', () {
        final q = Quantity(value: Decimal('500'), unit: ComparisonUnit.gram).normalize();
        expect(q.value.toPlainString(), '500');
        expect(q.unit, ComparisonUnit.gram);
      });

      test('キログラムをグラムに変換する', () {
        final q = Quantity(value: Decimal('2'), unit: ComparisonUnit.kilogram).normalize();
        expect(q.value.toPlainString(), '2000');
        expect(q.unit, ComparisonUnit.gram);
      });

      test('ミリリットルはそのまま', () {
        final q = Quantity(value: Decimal('350'), unit: ComparisonUnit.milliliter).normalize();
        expect(q.value.toPlainString(), '350');
        expect(q.unit, ComparisonUnit.milliliter);
      });

      test('リットルをミリリットルに変換する', () {
        final q = Quantity(value: Decimal('1.5'), unit: ComparisonUnit.liter).normalize();
        expect(q.value.toPlainString(), '1500');
        expect(q.unit, ComparisonUnit.milliliter);
      });

      test('個はそのまま', () {
        final q = Quantity(value: Decimal('3'), unit: ComparisonUnit.count).normalize();
        expect(q.value.toPlainString(), '3');
        expect(q.unit, ComparisonUnit.count);
      });
    });

    group('isCompatibleWith', () {
      test('同じ次元の単位は互換性がある', () {
        final gram = Quantity(value: Decimal('500'), unit: ComparisonUnit.gram);
        final kg = Quantity(value: Decimal('1'), unit: ComparisonUnit.kilogram);
        expect(gram.isCompatibleWith(kg), isTrue);
      });

      test('異なる次元の単位は互換性がない', () {
        final gram = Quantity(value: Decimal('500'), unit: ComparisonUnit.gram);
        final ml = Quantity(value: Decimal('500'), unit: ComparisonUnit.milliliter);
        expect(gram.isCompatibleWith(ml), isFalse);
      });

      test('同じ単位同士は互換性がある', () {
        final a = Quantity(value: Decimal('2'), unit: ComparisonUnit.count);
        final b = Quantity(value: Decimal('3'), unit: ComparisonUnit.count);
        expect(a.isCompatibleWith(b), isTrue);
      });
    });
  });
}
