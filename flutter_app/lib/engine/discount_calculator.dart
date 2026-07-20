import 'money.dart';
import 'offer.dart';
import 'rounding.dart';

class DiscountResult {
  final Money discountedAmount;
  final Money totalDiscount;

  const DiscountResult({
    required this.discountedAmount,
    required this.totalDiscount,
  });
}

abstract final class DiscountCalculator {
  static DiscountResult applyItemDiscounts(
    Money baseAmount,
    List<Discount> discounts,
  ) {
    var currentAmount = baseAmount;
    var totalDiscount = Money.zero;

    for (final discount in discounts) {
      if (discount is FixedAmountDiscount ||
          discount is PercentageDiscount) {
        final discountAmount = discount.calculateAmount(currentAmount);
        currentAmount = currentAmount - discountAmount;
        totalDiscount = totalDiscount + discountAmount;
      }
    }

    return DiscountResult(
      discountedAmount: Rounding.roundMoney(currentAmount.amount),
      totalDiscount: Rounding.roundMoney(totalDiscount.amount),
    );
  }

  static DiscountResult applyCoupons(
    Money baseAmount,
    List<CouponDiscount> coupons,
  ) {
    var currentAmount = baseAmount;
    var totalCoupon = Money.zero;

    for (final coupon in coupons) {
      final discountAmount = coupon.calculateAmount(currentAmount);
      currentAmount = currentAmount - discountAmount;
      totalCoupon = totalCoupon + discountAmount;
    }

    return DiscountResult(
      discountedAmount: Rounding.roundMoney(currentAmount.amount),
      totalDiscount: Rounding.roundMoney(totalCoupon.amount),
    );
  }
}
