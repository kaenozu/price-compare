package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/Decimal.kt
 *
 * 任意精度10進数の共通契約（expect宣言）。
 * JVM/AndroidではBigDecimalで実装される。
 * 金額計算での浮動小数点誤差を防止するため存在する。
 *
 * 関連ファイル:
 * - src/jvmMain/kotlin/com/pricecompare/model/DecimalJvm.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Money.kt
 * - src/commonMain/kotlin/com/pricecompare/util/Rounding.kt
 */
expect class Decimal(value: String) {
    operator fun plus(other: Decimal): Decimal
    operator fun minus(other: Decimal): Decimal
    operator fun times(other: Decimal): Decimal
    operator fun div(other: Decimal): Decimal
    operator fun unaryMinus(): Decimal
    fun compareTo(other: Decimal): Int
    fun stripTrailingZeros(): Decimal
    fun toPlainString(): String

    companion object {
        val ZERO: Decimal
        val ONE: Decimal
        fun fromLong(value: Long): Decimal
    }
}

operator fun Decimal.compareTo(other: Decimal): Int = this.compareTo(other)
