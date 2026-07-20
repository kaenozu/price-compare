package com.pricecompare.pricing

import com.pricecompare.model.Decimal
import com.pricecompare.model.Money
import com.pricecompare.model.Offer
import com.pricecompare.model.PriceBreakdown
import com.pricecompare.model.PurchaseContext

/**
 * src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 *
 * 商品の価格計算を担当するコアクラス。
 * Offer と PurchaseContext を受け取り、PriceBreakdown を返す。
 *
 * 計算順序:
 * 1. 税抜価格
 * 2. 税計算
 * 3. 商品値引き
 * 4. クーポン適用
 * 5. 使用ポイント充当
 * 6. 送料加算
 * 7. 獲得ポイント評価
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Offer.kt
 * - src/commonMain/kotlin/com/pricecompare/model/PurchaseContext.kt
 * - src/commonMain/kotlin/com/pricecompare/model/PriceBreakdown.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/TaxCalculator.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/DiscountCalculator.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/UnitNormalizer.kt
 */
object PriceCalculator {

    /**
     * Offer と PurchaseContext から PriceBreakdown を計算する。
     */
    fun calculate(offer: Offer, context: PurchaseContext): PriceBreakdown {
        val warnings = mutableListOf<String>()

        // 1. 税抜価格
        val baseExcludingTax = TaxCalculator.basePriceExcludingTax(
            offer.displayedPrice, offer.taxMode, offer.taxRate
        )

        // 2. 税計算
        val taxAmount = TaxCalculator.taxAmount(baseExcludingTax, offer.taxRate)
        // 税込表示の場合は表示価格そのまま（端数の再計算によるズレを防止）
        val priceIncludingTax = TaxCalculator.priceIncludingTax(
            baseExcludingTax, offer.taxRate,
            originalPrice = if (offer.taxMode == com.pricecompare.model.TaxMode.TAX_INCLUDED) offer.displayedPrice else null
        )

        // 3. 商品値引き
        val itemDiscountResult = DiscountCalculator.applyItemDiscounts(
            priceIncludingTax, offer.discounts
        )

        // 4. クーポン適用
        val couponResult = DiscountCalculator.applyCoupons(
            itemDiscountResult.discountedAmount, context.orderCoupons
        )

        // 5. 送料無料条件判定（クーポン適用後・ポイント使用前の金額）
        val effectiveShipping = context.effectiveShipping(couponResult.discountedAmount)
        if (context.shippingCost == null) {
            warnings.add("送料が未入力のため、確定比較ではありません")
        }

        // 6. 支払額計算（送料未入力の場合は0円として計算）
        val shippingForCalc = effectiveShipping ?: Money.ZERO
        val payableNow = couponResult.discountedAmount + shippingForCalc - context.usedPointsValue()

        // 7. 獲得ポイント評価
        val earnedPointsValue = context.earnedPointsValue()

        // 8. 実質負担額
        val effectiveCost = payableNow - earnedPointsValue

        // 9. 単位価格
        val unitPrice = UnitNormalizer.calculateUnitPrice(
            price = effectiveCost ?: couponResult.discountedAmount,
            quantity = offer.quantity
        )

        return PriceBreakdown(
            basePriceExcludingTax = baseExcludingTax,
            taxAmount = taxAmount,
            priceIncludingTax = priceIncludingTax,
            totalItemDiscount = itemDiscountResult.totalDiscount,
            totalCouponDiscount = couponResult.totalDiscount,
            pointRedemption = context.usedPointsValue(),
            shippingCost = effectiveShipping,
            payableNow = payableNow,
            earnedPointsValue = earnedPointsValue,
            effectiveCost = effectiveCost,
            unitPrice = unitPrice,
            warnings = warnings
        )
    }
}
