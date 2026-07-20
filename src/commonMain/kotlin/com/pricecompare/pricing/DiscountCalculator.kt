package com.pricecompare.pricing

import com.pricecompare.model.Decimal
import com.pricecompare.model.Discount
import com.pricecompare.model.Money
import com.pricecompare.util.Rounding

/**
 * src/commonMain/kotlin/com/pricecompare/pricing/DiscountCalculator.kt
 *
 * 割引適用を担当するユーティリティ。
 * 割引リストを適用順序（リスト順）に処理し、合計割引額を返す。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Discount.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Money.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Offer.kt
 */
object DiscountCalculator {

    /**
     * 商品割引（Percentage, FixedAmount）のみを適用する。
     * クーポン、ポイントは別途処理。
     */
    fun applyItemDiscounts(baseAmount: Money, discounts: List<Discount>): DiscountResult {
        var currentAmount = baseAmount
        var totalDiscount = Money.ZERO

        for (discount in discounts) {
            when (discount) {
                is Discount.PercentageDiscount,
                is Discount.FixedAmount -> {
                    val discountAmount = discount.calculateAmount(currentAmount)
                    currentAmount = currentAmount - discountAmount
                    totalDiscount = totalDiscount + discountAmount
                }
                // クーポンとポイントは item discounts では無視
                is Discount.CouponDiscount,
                is Discount.PointRedemption -> {}
            }
        }

        return DiscountResult(
            discountedAmount = Rounding.roundMoney(currentAmount.amount),
            totalDiscount = Rounding.roundMoney(totalDiscount.amount)
        )
    }

    /**
     * クーポン割引を適用する。
     */
    fun applyCoupons(baseAmount: Money, coupons: List<Discount.CouponDiscount>): DiscountResult {
        var currentAmount = baseAmount
        var totalCoupon = Money.ZERO

        for (coupon in coupons) {
            val discountAmount = coupon.calculateAmount(currentAmount)
            currentAmount = currentAmount - discountAmount
            totalCoupon = totalCoupon + discountAmount
        }

        return DiscountResult(
            discountedAmount = Rounding.roundMoney(currentAmount.amount),
            totalDiscount = Rounding.roundMoney(totalCoupon.amount)
        )
    }

    /**
     * 割引適用結果を保持するデータクラス。
     */
    data class DiscountResult(
        val discountedAmount: Money,
        val totalDiscount: Money
    )
}
