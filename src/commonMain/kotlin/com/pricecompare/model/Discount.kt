package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/Discount.kt
 *
 * 割引を表すsealed class。
 * 割引の種類ごとにサブクラスを持ち、適用順序に従って計算される。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Offer.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/DiscountCalculator.kt
 * - src/commonMain/kotlin/com/pricecompare/model/PriceBreakdown.kt
 */
sealed class Discount {
    /** 割引の適用対象金額を計算する */
    abstract fun calculateAmount(baseAmount: Money): Money

    /** 割引の説明 */
    abstract fun description(): String

    /** 割引率（パーセンテージ）を返す。固定額の場合はnull */
    fun percentage(): Decimal? = (this as? PercentageDiscount)?.rate

    /** 固定額割引 */
    data class FixedAmount(val amount: Money) : Discount() {
        override fun calculateAmount(baseAmount: Money): Money = amount
        override fun description(): String = "${amount}円引き"
    }

    /** 割引率割引 */
    data class PercentageDiscount(val rate: Decimal) : Discount() {
        override fun calculateAmount(baseAmount: Money): Money =
            Money(baseAmount.amount * rate)
        override fun description(): String = "${rate.toPlainString()}%引き"
    }

    /** クーポン割引 */
    data class CouponDiscount(val amount: Money, val name: String = "") : Discount() {
        override fun calculateAmount(baseAmount: Money): Money = amount
        override fun description(): String =
            if (name.isNotEmpty()) "クーポン($name): ${amount}円引き"
            else "クーポン: ${amount}円引き"
    }

    /** ポイント充当 */
    data class PointRedemption(val points: Int, val evaluationRate: Decimal = Decimal.ONE) : Discount() {
        override fun calculateAmount(baseAmount: Money): Money =
            Money(Decimal.fromLong(points.toLong()) * evaluationRate)
        override fun description(): String = "${points}ポイント使用"
    }
}
