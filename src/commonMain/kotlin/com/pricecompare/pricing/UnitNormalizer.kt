package com.pricecompare.pricing

import com.pricecompare.model.Decimal
import com.pricecompare.model.Money
import com.pricecompare.model.Quantity
import com.pricecompare.util.Rounding

/**
 * src/commonMain/kotlin/com/pricecompare/pricing/UnitNormalizer.kt
 *
 * 単位の正規化と単位価格の計算を担当するユーティリティ。
 * 異次元同士の比較を防止する。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Quantity.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Unit.kt
 * - src/commonMain/kotlin/com/pricecompare/comparison/ComparisonEngine.kt
 */
object UnitNormalizer {

    /**
     * 基準単位に正規化した数量を返す。
     * 異次元の場合はnullを返す。
     */
    fun normalizeQuantity(quantity: Quantity): Quantity? {
        return try {
            quantity.normalize()
        } catch (e: Exception) {
            null
        }
    }

    /**
     * 2つの数量が比較可能かどうかを判定する。
     */
    fun areComparable(quantityA: Quantity, quantityB: Quantity): Boolean {
        val normalizedA = normalizeQuantity(quantityA) ?: return false
        val normalizedB = normalizeQuantity(quantityB) ?: return false
        return normalizedA.unit == normalizedB.unit
    }

    /**
     * 単位価格（100g/mlあたり）を計算する。
     * 異次元の場合はnullを返す。
     */
    fun calculateUnitPrice(price: Money, quantity: Quantity, displayPer: Int = 100): Decimal? {
        val normalized = normalizeQuantity(quantity) ?: return null
        if (normalized.value.compareTo(Decimal.ZERO) <= 0) return null

        val factor = Decimal.fromLong(displayPer.toLong())
        val unitPrice = (price.amount * factor) / normalized.value
        return Rounding.roundUnitPrice(unitPrice)
    }
}
