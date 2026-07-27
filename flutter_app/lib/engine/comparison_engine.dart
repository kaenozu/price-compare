import 'decimal.dart';
import 'money.dart';
import 'offer.dart';
import 'price_breakdown.dart';
import 'price_calculator.dart';
import 'purchase_context.dart';
import 'rounding.dart';
import 'unit_normalizer.dart';

enum ComparisonWinner { productA, productB, tie }

class ComparisonResult {
  final PriceBreakdown breakdownA;
  final PriceBreakdown breakdownB;
  final ComparisonWinner? cheapestByPayable;
  final ComparisonWinner? cheapestByEffective;
  final ComparisonWinner? cheapestByUnitPrice;
  final Money payableDifference;
  final Money effectiveDifference;
  final Decimal? unitPriceDifferenceRatio;
  final List<String> warnings;
  final String? incompatibilityReason;

  const ComparisonResult({
    required this.breakdownA,
    required this.breakdownB,
    required this.cheapestByPayable,
    required this.cheapestByEffective,
    required this.cheapestByUnitPrice,
    required this.payableDifference,
    required this.effectiveDifference,
    required this.unitPriceDifferenceRatio,
    required this.warnings,
    required this.incompatibilityReason,
  });

  bool get isComparable => incompatibilityReason == null;
}

abstract final class ComparisonEngine {
  static ComparisonResult compare({
    required Offer offerA,
    required PurchaseContext contextA,
    required Offer offerB,
    required PurchaseContext contextB,
  }) {
    final breakdownA = PriceCalculator.calculate(offerA, contextA);
    final breakdownB = PriceCalculator.calculate(offerB, contextB);
    final warnings = {
      ...breakdownA.warnings,
      ...breakdownB.warnings,
    }.toList(growable: false);

    if (!UnitNormalizer.areComparable(offerA.quantity, offerB.quantity)) {
      return ComparisonResult(
        breakdownA: breakdownA,
        breakdownB: breakdownB,
        cheapestByPayable: null,
        cheapestByEffective: null,
        cheapestByUnitPrice: null,
        payableDifference: (breakdownA.payableNow - breakdownB.payableNow)
            .abs(),
        effectiveDifference:
            (breakdownA.effectiveCost - breakdownB.effectiveCost).abs(),
        unitPriceDifferenceRatio: null,
        warnings: warnings,
        incompatibilityReason:
            '単位が異なります（${offerA.quantity.unit.symbol} vs '
            '${offerB.quantity.unit.symbol}）。直接比較できません。',
      );
    }

    return ComparisonResult(
      breakdownA: breakdownA,
      breakdownB: breakdownB,
      cheapestByPayable: _compareMoney(
        breakdownA.payableNow,
        breakdownB.payableNow,
      ),
      cheapestByEffective: _compareMoney(
        breakdownA.effectiveCost,
        breakdownB.effectiveCost,
      ),
      cheapestByUnitPrice: _compareDecimal(
        breakdownA.unitPrice,
        breakdownB.unitPrice,
      ),
      payableDifference: (breakdownA.payableNow - breakdownB.payableNow).abs(),
      effectiveDifference: (breakdownA.effectiveCost - breakdownB.effectiveCost)
          .abs(),
      unitPriceDifferenceRatio: _unitPriceDifferenceRatio(
        breakdownA.unitPrice,
        breakdownB.unitPrice,
      ),
      warnings: warnings,
      incompatibilityReason: null,
    );
  }

  static ComparisonWinner _compareMoney(Money a, Money b) =>
      switch (a.compareTo(b)) {
        < 0 => ComparisonWinner.productA,
        > 0 => ComparisonWinner.productB,
        _ => ComparisonWinner.tie,
      };

  static ComparisonWinner? _compareDecimal(Decimal? a, Decimal? b) {
    if (a == null || b == null) {
      return null;
    }
    return switch (a.compareTo(b)) {
      < 0 => ComparisonWinner.productA,
      > 0 => ComparisonWinner.productB,
      _ => ComparisonWinner.tie,
    };
  }

  static Decimal? _unitPriceDifferenceRatio(Decimal? a, Decimal? b) {
    if (a == null || b == null || b.isZero) {
      return null;
    }
    return Rounding.roundUnitPrice((a - b) / b);
  }
}
