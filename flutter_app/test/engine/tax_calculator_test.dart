import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/decimal.dart';
import 'package:price_compare_flutter/engine/money.dart';
import 'package:price_compare_flutter/engine/tax_calculator.dart';
import 'package:price_compare_flutter/engine/tax_mode.dart';

void main() {
  group('TaxCalculator', () {
    test('税込価格は表示価格を保持して税抜価格と税額を算出する', () {
      final displayed = Money.of('110');
      final rate = Decimal('0.1');

      final base = TaxCalculator.basePriceExcludingTax(
        displayed,
        TaxMode.taxIncluded,
        rate,
      );
      final tax = TaxCalculator.taxAmount(base, rate);
      final included = TaxCalculator.priceIncludingTax(
        base,
        rate,
        originalPrice: displayed,
      );

      expect(base.amount.toPlainString(), '100');
      expect(tax.amount.toPlainString(), '10');
      expect(included.amount.toPlainString(), '110');
    });

    test('税抜価格には税額を加算する', () {
      final base = Money.of('900');
      final rate = Decimal('0.1');

      expect(
        TaxCalculator.taxAmount(base, rate).amount.toPlainString(),
        '90',
      );
      expect(
        TaxCalculator.priceIncludingTax(base, rate).amount.toPlainString(),
        '990',
      );
    });
  });
}
