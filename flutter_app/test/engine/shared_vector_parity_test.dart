import 'dart:convert';
import 'dart:io';

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
  final cases = _loadCases();

  for (final testCase in cases) {
    test('shared vector: ${testCase['name']}', () {
      final offer = Offer(
        productName: testCase['name']! as String,
        displayedPrice: Money.of(testCase['displayedPrice']! as String),
        taxMode: switch (testCase['taxMode']) {
          'included' => TaxMode.taxIncluded,
          'excluded' => TaxMode.taxExcluded,
          final value => throw FormatException('Unknown tax mode: $value'),
        },
        taxRate: Decimal(testCase['taxRate']! as String),
        quantity: Quantity(
          value: Decimal(testCase['quantity']! as String),
          unit: _unit(testCase['unit']! as String),
        ),
      );
      final context = PurchaseContext(
        shippingCost: Money.of(testCase['shippingCost']! as String),
        usedPoints: testCase['usedPoints']! as int,
        earnedPoints: testCase['earnedPoints']! as int,
        pointEvaluationRate: Decimal(
          testCase['pointEvaluationRate']! as String,
        ),
      );

      final result = PriceCalculator.calculate(offer, context);

      expect(
        result.payableNow.amount.toPlainString(),
        testCase['expectedPayableNow'],
      );
      expect(
        result.effectiveCost.amount.toPlainString(),
        testCase['expectedEffectiveCost'],
      );
      expect(result.unitPrice?.toPlainString(), testCase['expectedUnitPrice']);
    });
  }
}

List<Map<String, Object?>> _loadCases() {
  final raw = File(
    '../test_vectors/price_breakdown_cases.json',
  ).readAsStringSync();
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((entry) => Map<String, Object?>.from(entry as Map))
      .toList(growable: false);
}

ComparisonUnit _unit(String symbol) => switch (symbol) {
      'g' => ComparisonUnit.gram,
      'kg' => ComparisonUnit.kilogram,
      'ml' => ComparisonUnit.milliliter,
      'L' => ComparisonUnit.liter,
      '個' => ComparisonUnit.count,
      _ => throw FormatException('Unknown comparison unit: $symbol'),
    };
