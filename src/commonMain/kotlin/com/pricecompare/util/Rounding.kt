package com.pricecompare.util

import com.pricecompare.model.Decimal
import com.pricecompare.model.Money

/**
 * src/commonMain/kotlin/com/pricecompare/util/Rounding.kt
 *
 * 丸め処理を担当するユーティリティ。
 * すべての金額計算でHALF_UPを統一する。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Money.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Decimal.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 */
object Rounding {

    /**
     * 金額の丸め（小数点以下を切り上げ、整数部分のみ）。
     */
    fun roundMoney(value: Decimal): Money {
        val plainString = value.toPlainString()
        val parts = plainString.split(".")
        val integerPart = parts[0]

        if (parts.size == 1) return Money(Decimal(integerPart))

        val decimalPart = parts[1]
        if (decimalPart.isEmpty()) return Money(Decimal(integerPart))

        // 小数点第1位でHALF_UP
        val firstDigit = decimalPart[0].digitToInt()
        val result = if (firstDigit >= 5) {
            // 整数部を+1
            val isNegative = integerPart.startsWith("-")
            val absInt = if (isNegative) integerPart.removePrefix("-") else integerPart
            val incremented = (absInt.toLong() + 1).toString()
            if (isNegative) "-$incremented" else incremented
        } else {
            integerPart
        }

        return Money(Decimal(result))
    }

    /**
     * 単位価格の丸め（小数点以下6桁 HALF_UP）。
     */
    fun roundUnitPrice(value: Decimal): Decimal {
        val plainString = value.toPlainString()
        val parts = plainString.split(".")

        if (parts.size == 1) return value

        val integerPart = parts[0]
        var decimalPart = parts[1]

        if (decimalPart.length <= 6) return value

        // 7桁目でHALF_UP
        val seventhDigit = decimalPart[6].digitToInt()
        decimalPart = decimalPart.substring(0, 6)
        if (seventhDigit >= 5) {
            // 6桁目をインクリメント
            val lastDigit = decimalPart.last().digitToInt()
            if (lastDigit < 9) {
                decimalPart = decimalPart.dropLast(1) + (lastDigit + 1).toString()
            } else {
                decimalPart = decimalPart.dropLast(1) + "0"
            }
        }

        return Decimal("$integerPart.$decimalPart")
    }

    /**
     * 割引率の計算。
     */
    fun calculateDiscountRate(original: Money, discounted: Money): Decimal {
        if (original.isZero()) return Decimal.ZERO
        return (original.amount - discounted.amount) / original.amount
    }
}
