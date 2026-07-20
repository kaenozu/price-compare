package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/Offer.kt
 *
 * 1つの商品提供を表すデータクラス。
 * 店舗、価格、税区分、数量、割引情報を含む。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Money.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Discount.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Quantity.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 */
data class Offer(
    val productName: String,
    val storeName: String = "",
    val displayedPrice: Money,
    val taxMode: TaxMode,
    val taxRate: Decimal,
    val quantity: Quantity,
    val discounts: List<Discount> = emptyList()
) {
    init {
        require(taxRate.compareTo(Decimal.ZERO) >= 0) { "税率は0以上である必要がある" }
        require(quantity.value.compareTo(Decimal.ZERO) > 0) { "数量は0より大きい必要がある" }
    }

    /**
     * 税抜価格を計算する。
     * 税込の場合は逆算、税抜の場合はそのまま。
     */
    fun basePriceExcludingTax(): Money = when (taxMode) {
        TaxMode.TAX_EXCLUDED -> displayedPrice
        TaxMode.TAX_INCLUDED -> {
            val divisor = Decimal.ONE + taxRate
            Money(displayedPrice.amount / divisor)
        }
    }

    /**
     * 税額を計算する。
     */
    fun taxAmount(): Money {
        val base = basePriceExcludingTax()
        return Money(base.amount * taxRate)
    }

    /**
     * 税込価格（割引適用前）を計算する。
     */
    fun priceIncludingTax(): Money = when (taxMode) {
        TaxMode.TAX_INCLUDED -> displayedPrice
        TaxMode.TAX_EXCLUDED -> {
            val base = basePriceExcludingTax()
            val tax = Money(base.amount * taxRate)
            base + tax
        }
    }
}
