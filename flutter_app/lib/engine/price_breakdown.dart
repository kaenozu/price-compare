import 'decimal.dart';
import 'money.dart';

class PriceBreakdown {
  final Money basePriceExcludingTax;
  final Money taxAmount;
  final Money priceIncludingTax;
  final Money totalItemDiscount;
  final Money totalCouponDiscount;
  final Money pointRedemption;
  final Money? shippingCost;
  final Money payableNow;
  final Money earnedPointsValue;
  final Money effectiveCost;
  final Decimal? unitPrice;
  final List<String> warnings;

  const PriceBreakdown({
    required this.basePriceExcludingTax,
    required this.taxAmount,
    required this.priceIncludingTax,
    required this.totalItemDiscount,
    required this.totalCouponDiscount,
    required this.pointRedemption,
    required this.shippingCost,
    required this.payableNow,
    required this.earnedPointsValue,
    required this.effectiveCost,
    required this.unitPrice,
    this.warnings = const [],
  });
}
