package com.pricecompare.comparison

import com.pricecompare.model.Decimal
import com.pricecompare.model.ComparisonResult
import com.pricecompare.model.Money
import com.pricecompare.model.Offer
import com.pricecompare.model.PriceBreakdown
import com.pricecompare.model.PurchaseContext
import com.pricecompare.pricing.PriceCalculator
import com.pricecompare.pricing.UnitNormalizer
import com.pricecompare.util.Rounding

/**
 * src/commonMain/kotlin/com/pricecompare/comparison/ComparisonEngine.kt
 *
 * 2商品比較のコアロジックを担当する。
 * 各商品のPriceBreakdownを比較し、ComparisonResultを返す。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/ComparisonResult.kt
 * - src/commonMain/kotlin/com/pricecompare/model/PriceBreakdown.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/UnitNormalizer.kt
 */
object ComparisonEngine {

    fun compare(
        offerA: Offer,
        contextA: PurchaseContext,
        offerB: Offer,
        contextB: PurchaseContext
    ): ComparisonResult {
        val breakdownA = PriceCalculator.calculate(offerA, contextA)
        val breakdownB = PriceCalculator.calculate(offerB, contextB)

        val warnings = (breakdownA.warnings + breakdownB.warnings).distinct()

        if (!UnitNormalizer.areComparable(offerA.quantity, offerB.quantity)) {
            return ComparisonResult.incompatible(
                breakdownA = breakdownA,
                breakdownB = breakdownB,
                reason = "単位が異なります（${offerA.quantity.unit.symbol} vs ${offerB.quantity.unit.symbol}）。直接比較できません。",
                warnings = warnings
            )
        }

        val cheapestByPayable = comparePayable(breakdownA, breakdownB)
        val cheapestByEffective = compareEffective(breakdownA, breakdownB)
        val cheapestByUnitPrice = compareUnitPrice(breakdownA, breakdownB)
        val payableDifference = calculatePayableDifference(breakdownA, breakdownB)
        val effectiveDifference = calculateEffectiveDifference(breakdownA, breakdownB)
        val unitPriceDifferenceRatio = calculateUnitPriceRatio(breakdownA, breakdownB)

        return ComparisonResult(
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

    private fun comparePayable(a: PriceBreakdown, b: PriceBreakdown): Int? {
        return when {
            a.payableNow.amount.compareTo(b.payableNow.amount) < 0 -> 0
            a.payableNow.amount.compareTo(b.payableNow.amount) > 0 -> 1
            else -> null
        }
    }

    private fun compareEffective(a: PriceBreakdown, b: PriceBreakdown): Int? {
        return when {
            a.effectiveCost.amount.compareTo(b.effectiveCost.amount) < 0 -> 0
            a.effectiveCost.amount.compareTo(b.effectiveCost.amount) > 0 -> 1
            else -> null
        }
    }

    private fun compareUnitPrice(a: PriceBreakdown, b: PriceBreakdown): Int? {
        val unitA = a.unitPrice ?: return null
        val unitB = b.unitPrice ?: return null
        return when {
            unitA.compareTo(unitB) < 0 -> 0
            unitA.compareTo(unitB) > 0 -> 1
            else -> null
        }
    }

    private fun calculatePayableDifference(a: PriceBreakdown, b: PriceBreakdown): Money {
        return (a.payableNow - b.payableNow).abs()
    }

    private fun calculateEffectiveDifference(a: PriceBreakdown, b: PriceBreakdown): Money {
        return (a.effectiveCost - b.effectiveCost).abs()
    }

    private fun calculateUnitPriceRatio(a: PriceBreakdown, b: PriceBreakdown): Decimal? {
        val unitA = a.unitPrice ?: return null
        val unitB = b.unitPrice ?: return null
        if (unitB.compareTo(Decimal.ZERO) == 0) return null
        val diff = unitA - unitB
        return Rounding.roundUnitPrice(diff / unitB)
    }
}
