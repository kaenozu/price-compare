package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/ComparisonResult.kt
 *
 * 2商品比較の結果を表すデータクラス。
 * 最安候補、差額、差率、警告を含む。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/PriceBreakdown.kt
 * - src/commonMain/kotlin/com/pricecompare/comparison/ComparisonEngine.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Money.kt
 */
data class ComparisonResult(
    /** 商品Aの内訳 */
    val breakdownA: PriceBreakdown,

    /** 商品Bの内訳 */
    val breakdownB: PriceBreakdown,

    /** 支払額ベースの最安候補（null = 比較不能） */
    val cheapestByPayable: Int?,

    /** 実質負担額ベースの最安候補（null = 比較不能） */
    val cheapestByEffective: Int?,

    /** 単位価格ベースの最安候補（null = 比較不能） */
    val cheapestByUnitPrice: Int?,

    /** 支払額の差 */
    val payableDifference: Money?,

    /** 実質負担額の差 */
    val effectiveDifference: Money?,

    /** 単位価格の差率 */
    val unitPriceDifferenceRatio: Decimal?,

    /** 警告メッセージ */
    val warnings: List<String>,

    /** 比較不能理由 */
    val incompatibilityReason: String?
) {
    /**
     * 比較が可能かどうかを判定する。
     */
    fun isComparable(): Boolean = incompatibilityReason == null

    companion object {
        /**
         * 比較不能な結果を生成する。
         */
        fun incompatible(
            breakdownA: PriceBreakdown,
            breakdownB: PriceBreakdown,
            reason: String,
            warnings: List<String> = emptyList()
        ): ComparisonResult = ComparisonResult(
            breakdownA = breakdownA,
            breakdownB = breakdownB,
            cheapestByPayable = null,
            cheapestByEffective = null,
            cheapestByUnitPrice = null,
            payableDifference = null,
            effectiveDifference = null,
            unitPriceDifferenceRatio = null,
            warnings = warnings,
            incompatibilityReason = reason
        )
    }
}
