package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/PurchaseContext.kt
 *
 * 購入コンテキストを表すデータクラス。
 * 商品単位の情報を超える、注文全体の情報を含む。
 * 送料、注文クーポン、ポイント情報を管理する。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Money.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Discount.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 */
data class PurchaseContext(
    /** 送料（null=未入力） */
    val shippingCost: Money? = null,

    /** 送料無料条件（この金額以上で送料無料） */
    val freeShippingThreshold: Money? = null,

    /** 注文全体に適用されるクーポン */
    val orderCoupons: List<Discount.CouponDiscount> = emptyList(),

    /** 使用ポイント */
    val usedPoints: Int = 0,

    /** 獲得予定ポイント */
    val earnedPoints: Int = 0,

    /** ポイント評価率（1.0 = 1ポイント1円） */
    val pointEvaluationRate: Decimal = Decimal.ONE
) {
    /**
     * 送料無料条件を満たすかどうかを判定する。
     * クーポン適用後・ポイント使用前の金額で判定。
     */
    fun isShippingFree(subtotalAfterCoupons: Money): Boolean {
        val threshold = freeShippingThreshold ?: return false
        return subtotalAfterCoupons.amount.compareTo(threshold.amount) >= 0
    }

    /**
     * 実送料を計算する。
     * 送料未入力の場合はnullを返す。
     */
    fun effectiveShipping(subtotalAfterCoupons: Money): Money? {
        if (shippingCost == null) return null
        if (isShippingFree(subtotalAfterCoupons)) return Money.ZERO
        return shippingCost
    }

    /**
     * 獲得ポイントの評価額を計算する。
     */
    fun earnedPointsValue(): Money =
        Money(Decimal.fromLong(earnedPoints.toLong()) * pointEvaluationRate)

    /**
     * 使用ポイントの評価額を計算する。
     */
    fun usedPointsValue(): Money =
        Money(Decimal.fromLong(usedPoints.toLong()) * pointEvaluationRate)
}
