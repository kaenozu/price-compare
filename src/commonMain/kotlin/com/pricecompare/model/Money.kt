package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/Money.kt
 *
 * 金額を表す値オブジェクト。JPY固定、小数点なし。
 * BigDecimalではなくDecimalを使用してKMP対応を実現。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Decimal.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 * - src/commonMain/kotlin/com/pricecompare/model/PriceBreakdown.kt
 */
data class Money(val amount: Decimal) {

    operator fun plus(other: Money): Money = Money(amount + other.amount)
    operator fun minus(other: Money): Money = Money(amount - other.amount)
    operator fun times(factor: Decimal): Money = Money(amount * factor)
    operator fun div(other: Money): Decimal = amount / other.amount
    operator fun unaryMinus(): Money = Money(-amount)

    fun isPositive(): Boolean = amount.compareTo(Decimal.ZERO) > 0
    fun isNegative(): Boolean = amount.compareTo(Decimal.ZERO) < 0
    fun isZero(): Boolean = amount.compareTo(Decimal.ZERO) == 0

    fun abs(): Money = if (isNegative()) Money(-amount) else this

    override fun toString(): String = "${amount.toPlainString()}円"

    companion object {
        val ZERO = Money(Decimal.ZERO)

        fun of(value: Long): Money = Money(Decimal.fromLong(value))
        fun of(value: String): Money = Money(Decimal(value))
    }
}

operator fun Decimal.times(money: Money): Money = money * this
