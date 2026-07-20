package com.pricecompare.pricing

import com.pricecompare.model.Decimal
import com.pricecompare.model.Money
import com.pricecompare.model.TaxMode
import com.pricecompare.util.Rounding

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
                // 税抜 = 税込 - 税額
                // 税額 = roundMoney(税込 × 税率 / (1 + 税率))
                val divisor = Decimal.ONE + taxRate
                val taxAmount = Rounding.roundMoney(price.amount * taxRate / divisor)
                price - taxAmount
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
     * 税込表示の場合は表示価格そのままを返す（端数の再計算によるズレを防ぐ）。
     */
    fun priceIncludingTax(basePrice: Money, taxRate: Decimal, originalPrice: Money? = null): Money {
        return originalPrice ?: (basePrice + taxAmount(basePrice, taxRate))
    }
}
