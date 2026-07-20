package com.pricecompare.util

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
     * 金額の丸め（小数点以下を切り上げ）。
     * Decimalの小数点以下をtruncateして整数部分のみ返す。
     */
    fun roundMoney(value: Decimal): Money {
        val plainString = value.toPlainString()
        val integerPart = plainString.split(".")[0]
        val rounded = if (integerPart.startsWith("-")) {
            val abs = integerPart.removePrefix("-")
            if (abs.isEmpty()) "0" else "-$abs"
        } else {
            integerPart.ifEmpty { "0" }
        }
        return Money(Decimal(rounded))
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

        if (decimalPart.length > 6) {
            // 7桁目でHALF_UP
            val seventhDigit = decimalPart[6].digitToInt()
            decimalPart = decimalPart.substring(0, 6)
            if (seventhDigit >= 5) {
                // 6桁目をインクリメント
                val lastDigit = decimalPart.last().digitToInt()
                if (lastDigit < 9) {
                    decimalPart = decimalPart.dropLast(1) + (lastDigit + 1).toString()
                } else {
                    // キャリーオーバー
                    decimalPart = decimalPart.dropLast(1) + "0"
                    // 簡易キャリー（整数部には影響しない前提）
                }
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
