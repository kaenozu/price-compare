import 'decimal.dart';
import 'money.dart';
import 'offer.dart';

class PurchaseContext {
  final Money? shippingCost;
  final Money? freeShippingThreshold;
  final List<CouponDiscount> orderCoupons;
  final int usedPoints;
  final int earnedPoints;
  final Decimal pointEvaluationRate;

  PurchaseContext({
    this.shippingCost,
    this.freeShippingThreshold,
    this.orderCoupons = const [],
    this.usedPoints = 0,
    this.earnedPoints = 0,
    Decimal? pointEvaluationRate,
  }) : pointEvaluationRate = pointEvaluationRate ?? Decimal.one {
    if (usedPoints < 0 || earnedPoints < 0) {
      throw ArgumentError('Points must be non-negative');
    }
    if (this.pointEvaluationRate < Decimal.zero ||
        this.pointEvaluationRate > Decimal('2')) {
      throw ArgumentError.value(
        this.pointEvaluationRate,
        'pointEvaluationRate',
        'must be between 0 and 2',
      );
    }
  }

  bool isShippingFree(Money subtotalAfterCoupons) {
    final threshold = freeShippingThreshold;
    return threshold != null && subtotalAfterCoupons.amount >= threshold.amount;
  }

  Money? effectiveShipping(Money subtotalAfterCoupons) {
    final shipping = shippingCost;
    if (shipping == null) {
      return null;
    }
    return isShippingFree(subtotalAfterCoupons) ? Money.zero : shipping;
  }

  Money earnedPointsValue() =>
      Money(Decimal.fromInt(earnedPoints) * pointEvaluationRate);

  Money usedPointsValue() =>
      Money(Decimal.fromInt(usedPoints) * pointEvaluationRate);
}
