package com.pricecompare.pricing

/**
 * src/commonMain/kotlin/com/pricecompare/pricing/TaxCalculator.kt
 *
 * 税計算を担当するユーティリティ。
 * 税込/税抜の変換、税額の計算を行う。
 * 各商品段階でHALF_UP丸めを適用する。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Money.kt
 * - src/commonMain/kotlin/com/pricecompare/model/TaxMode.kt
 * - src/commonMain/kotlin/com/pricecompare/util/Rounding.kt
 */
object TaxCalculator {

    /**
     * 税抜価格を計算する。
     * 税込の場合は逆算、税抜の場合はそのまま。
     */
    fun basePriceExcludingTax(price: Money, taxMode: TaxMode, taxRate: Decimal): Money {
        return when (taxMode) {
            TaxMode.TAX_EXCLUDED -> price
            TaxMode.TAX_INCLUDED -> {
                val divisor = Decimal.ONE + taxRate
                Rounding.roundMoney(price.amount / divisor)
            }
        }
    }

    /**
     * 税額を計算する。
     */
    fun taxAmount(basePrice: Money, taxRate: Decimal): Money {
        return Rounding.roundMoney(basePrice.amount * taxRate)
    }

    /**
     * 税込価格を計算する。
     */
    fun priceIncludingTax(basePrice: Money, taxRate: Decimal): Money {
        val tax = taxAmount(basePrice, taxRate)
        return basePrice + tax
    }
}
