package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/TaxMode.kt
 *
 * 税区分を定義するenum。
 * 商品の表示価格が税込か税抜かを表す。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Offer.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/TaxCalculator.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 */
enum class TaxMode {
    /** 税込価格 */
    TAX_INCLUDED,

    /** 税抜価格 */
    TAX_EXCLUDED;

    fun isTaxIncluded(): Boolean = this == TAX_INCLUDED
    fun isTaxExcluded(): Boolean = this == TAX_EXCLUDED
}
