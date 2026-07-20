package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/PriceBreakdown.kt
 *
 * 計算結果の内訳を表すデータクラス。
 * 各計算段階の金額を保持し、比較結果の説明に使用される。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Money.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Offer.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 */
data class PriceBreakdown(
    /** 税抜価格 */
    val basePriceExcludingTax: Money,

    /** 税額 */
    val taxAmount: Money,

    /** 税込価格（割引適用前） */
    val priceIncludingTax: Money,

    /** 商品割引合計 */
    val totalItemDiscount: Money,

    /** クーポン割引合計 */
    val totalCouponDiscount: Money,

    /** 使用ポイント充当額 */
    val pointRedemption: Money,

    /** 送料 */
    val shippingCost: Money?,

    /** 今回の支払額 */
    val payableNow: Money,

    /** 獲得ポイント評価額 */
    val earnedPointsValue: Money,

    /** 実質負担額 */
    val effectiveCost: Money,

    /** 単位価格（null = 容量未設定 or 次元不一致） */
    val unitPrice: Decimal?,

    /** 警告メッセージリスト */
    val warnings: List<String> = emptyList()
) {
    companion object {
        /**
         * 空のPriceBreakdownを生成する。
         */
        fun empty(): PriceBreakdown = PriceBreakdown(
            basePriceExcludingTax = Money.ZERO,
            taxAmount = Money.ZERO,
            priceIncludingTax = Money.ZERO,
            totalItemDiscount = Money.ZERO,
            totalCouponDiscount = Money.ZERO,
            pointRedemption = Money.ZERO,
            shippingCost = null,
            payableNow = Money.ZERO,
            earnedPointsValue = Money.ZERO,
            effectiveCost = Money.ZERO,
            unitPrice = null,
            warnings = emptyList()
        )
    }
}
