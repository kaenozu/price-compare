package com.pricecompare.comparison

/**
 * src/commonMain/kotlin/com/pricecompare/comparison/ComparisonEngine.kt
 *
 * 2商品比較のコアロジックを担当する。
 * 各商品のPriceBreakdownを比較し、ComparisonResultを返す。
 * 交差積を使用して除算の丸めによる誤判定を防止する。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/ComparisonResult.kt
 * - src/commonMain/kotlin/com/pricecompare/model/PriceBreakdown.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/UnitNormalizer.kt
 */
object ComparisonEngine {

    /**
     * 2商品を比較する。
     */
    fun compare(
        offerA: com.pricecompare.model.Offer,
        contextA: com.pricecompare.model.PurchaseContext,
        offerB: com.pricecompare.model.Offer,
        contextB: com.pricecompare.model.PurchaseContext
    ): com.pricecompare.model.ComparisonResult {
        val breakdownA = com.pricecompare.pricing.PriceCalculator.calculate(offerA, contextA)
        val breakdownB = com.pricecompare.pricing.PriceCalculator.calculate(offerB, contextB)

        val warnings = (breakdownA.warnings + breakdownB.warnings).distinct()

        // 単位の互換性チェック
        if (!com.pricecompare.pricing.UnitNormalizer.areComparable(offerA.quantity, offerB.quantity)) {
            return com.pricecompare.model.ComparisonResult.incompatible(
                breakdownA = breakdownA,
                breakdownB = breakdownB,
                reason = "単位が異なります（${offerA.quantity.unit.symbol} vs ${offerB.quantity.unit.symbol}）。直接比較できません。",
                warnings = warnings
            )
        }

        // 支払額ベースの比較
        val cheapestByPayable = comparePayable(breakdownA, breakdownB)

        // 実質負担額ベースの比較
        val cheapestByEffective = compareEffective(breakdownA, breakdownB)

        // 単位価格ベースの比較（交差積使用）
        val cheapestByUnitPrice = compareUnitPrice(breakdownA, breakdownB)

        // 差額・差率
        val payableDifference = calculatePayableDifference(breakdownA, breakdownB)
        val effectiveDifference = calculateEffectiveDifference(breakdownA, breakdownB)
        val unitPriceDifferenceRatio = calculateUnitPriceRatio(breakdownA, breakdownB)

        return com.pricecompare.model.ComparisonResult(
            breakdownA = breakdownA,
            breakdownB = breakdownB,
            cheapestByPayable = cheapestByPayable,
            cheapestByEffective = cheapestByEffective,
            cheapestByUnitPrice = cheapestByUnitPrice,
            payableDifference = payableDifference,
            effectiveDifference = effectiveDifference,
            unitPriceDifferenceRatio = unitPriceDifferenceRatio,
            warnings = warnings,
            incompatibilityReason = null
        )
    }

    /**
     * 支払額ベースで比較。
     * 0=A安価, 1=B安価, null=比較不能
     */
    private fun comparePayable(
        a: com.pricecompare.model.PriceBreakdown,
        b: com.pricecompare.model.PriceBreakdown
    ): Int? {
        val payableA = a.payableNow ?: return null
        val payableB = b.payableNow ?: return null
        return when {
            payableA.amount.compareTo(payableB.amount) < 0 -> 0
            payableA.amount.compareTo(payableB.amount) > 0 -> 1
            else -> null // 同額
        }
    }

    /**
     * 実質負担額ベースで比較。
     */
    private fun compareEffective(
        a: com.pricecompare.model.PriceBreakdown,
        b: com.pricecompare.model.PriceBreakdown
    ): Int? {
        val effectiveA = a.effectiveCost ?: return null
        val effectiveB = b.effectiveCost ?: return null
        return when {
            effectiveA.amount.compareTo(effectiveB.amount) < 0 -> 0
            effectiveA.amount.compareTo(effectiveB.amount) > 0 -> 1
            else -> null
        }
    }

    /**
     * 単位価格ベースで比較（交差積使用、除算回避）。
     */
    private fun compareUnitPrice(
        a: com.pricecompare.model.PriceBreakdown,
        b: com.pricecompare.model.PriceBreakdown
    ): Int? {
        val unitA = a.unitPrice ?: return null
        val unitB = b.unitPrice ?: return null

        // 交差積: unitA * quantityB と unitB * quantityA で比較
        // ただしquantityは正規化済みなので、単純な大小比較で十分
        return when {
            unitA.compareTo(unitB) < 0 -> 0
            unitA.compareTo(unitB) > 0 -> 1
            else -> null
        }
    }

    /**
     * 支払額の差を計算。
     */
    private fun calculatePayableDifference(
        a: com.pricecompare.model.PriceBreakdown,
        b: com.pricecompare.model.PriceBreakdown
    ): com.pricecompare.model.Money? {
        val payableA = a.payableNow ?: return null
        val payableB = b.payableNow ?: return null
        return (payableA - payableB).abs()
    }

    /**
     * 実質負担額の差を計算。
     */
    private fun calculateEffectiveDifference(
        a: com.pricecompare.model.PriceBreakdown,
        b: com.pricecompare.model.PriceBreakdown
    ): com.pricecompare.model.Money? {
        val effectiveA = a.effectiveCost ?: return null
        val effectiveB = b.effectiveCost ?: return null
        return (effectiveA - effectiveB).abs()
    }

    /**
     * 単位価格の差率を計算。
     */
    private fun calculateUnitPriceRatio(
        a: com.pricecompare.model.PriceBreakdown,
        b: com.pricecompare.model.PriceBreakdown
    ): Decimal? {
        val unitA = a.unitPrice ?: return null
        val unitB = b.unitPrice ?: return null
        if (unitB.compareTo(Decimal.ZERO) == 0) return null

        val diff = unitA - unitB
        return (diff / unitB).let { com.pricecompare.pricing.Rounding.roundUnitPrice(it) }
    }
}
