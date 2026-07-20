package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/Quantity.kt
 *
 * 商品の数量・容量を表す値オブジェクト。
 * 値と単位の組み合わせで構成される。
 * 異なる次元同士の比較は不可。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Unit.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/UnitNormalizer.kt
 * - src/commonMain/kotlin/com/pricecompare/comparison/ComparisonEngine.kt
 */
data class Quantity(
    val value: Decimal,
    val unit: ComparisonUnit
) {
    /**
     * 基準単位に変換する。
     * kg → g, L → ml, そのまま
     */
    fun normalize(): Quantity {
        val normalizedValue = value * Decimal(unit.conversionFactor)
        return Quantity(normalizedValue, unit.baseUnit())
    }

    fun isCompatibleWith(other: Quantity): Boolean =
        unit.baseUnit() == other.unit.baseUnit()

    override fun toString(): String = "${value.toPlainString()}${unit.symbol}"
}
