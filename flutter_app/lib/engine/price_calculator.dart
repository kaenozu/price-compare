import 'discount_calculator.dart';
import 'money.dart';
import 'offer.dart';
import 'price_breakdown.dart';
import 'purchase_context.dart';
import 'tax_calculator.dart';
import 'tax_mode.dart';
import 'unit_normalizer.dart';

abstract final class PriceCalculator {
  static PriceBreakdown calculate(Offer offer, PurchaseContext context) {
    final warnings = <String>[];

    final baseExcludingTax = TaxCalculator.basePriceExcludingTax(
      offer.displayedPrice,
      offer.taxMode,
      offer.taxRate,
    );
    final taxAmount = TaxCalculator.taxAmount(baseExcludingTax, offer.taxRate);
    final priceIncludingTax = TaxCalculator.priceIncludingTax(
      baseExcludingTax,
      offer.taxRate,
      originalPrice:
          offer.taxMode == TaxMode.taxIncluded ? offer.displayedPrice : null,
    );

    final itemDiscountResult = DiscountCalculator.applyItemDiscounts(
      priceIncludingTax,
      offer.discounts,
    );
    final couponResult = DiscountCalculator.applyCoupons(
      itemDiscountResult.discountedAmount,
      context.orderCoupons,
    );

    final effectiveShipping = context.effectiveShipping(
      couponResult.discountedAmount,
    );
    if (context.shippingCost == null) {
      warnings.add('送料が未入力のため、確定比較ではありません');
    }
    final shippingForCalculation = effectiveShipping ?? Money.zero;

    final pointRedemption = context.usedPointsValue();
    final payableNow = couponResult.discountedAmount +
        shippingForCalculation -
        pointRedemption;
    final earnedPointsValue = context.earnedPointsValue();
    final effectiveCost = payableNow - earnedPointsValue;
    if (effectiveCost.isNegative) {
      warnings.add('獲得ポイント評価額が支払額を上回っています');
    }

    final unitPrice = UnitNormalizer.calculateUnitPrice(
      price: effectiveCost,
      quantity: offer.quantity,
    );

    return PriceBreakdown(
      basePriceExcludingTax: baseExcludingTax,
      taxAmount: taxAmount,
      priceIncludingTax: priceIncludingTax,
      totalItemDiscount: itemDiscountResult.totalDiscount,
      totalCouponDiscount: couponResult.totalDiscount,
      pointRedemption: pointRedemption,
      shippingCost: effectiveShipping,
      payableNow: payableNow,
      earnedPointsValue: earnedPointsValue,
      effectiveCost: effectiveCost,
      unitPrice: unitPrice,
      warnings: warnings,
    );
  }
}
