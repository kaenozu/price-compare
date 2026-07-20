package com.pricecompare.model

/**
 * src/commonMain/kotlin/com/pricecompare/model/Unit.kt
 *
 * 商品の単位を定義するenum。
 * 重さ・容量・個数の3次元を扱い、異次元同士の比較を防止する。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/model/Quantity.kt
 * - src/commonMain/kotlin/com/pricecompare/pricing/UnitNormalizer.kt
 * - src/commonMain/kotlin/com/pricecompare/comparison/ComparisonEngine.kt
 */
enum class ComparisonUnit(
    val symbol: String,
    val dimension: String,
    val conversionFactor: String
) {
    // 重量（基準: g）
    GRAM("g", "weight", "1"),
    KILOGRAM("kg", "weight", "1000"),

    // 容量（基準: ml）
    MILLILITER("ml", "capacity", "1"),
    LITER("L", "capacity", "1000"),

    // 個数（基準: count）
    COUNT("個", "count", "1"),
    PIECE("枚", "count", "1"),
    BOTTLE("本", "count", "1"),
    BAG("袋", "count", "1");

    /**
     * 同一次元の基準単位を返す。
     */
    fun baseUnit(): ComparisonUnit = when (dimension) {
        "weight" -> GRAM
        "capacity" -> MILLILITER
        "count" -> COUNT
        else -> this
    }

    /**
     * 同一次元かどうかを判定する。
     */
    fun isSameDimension(other: ComparisonUnit): Boolean =
        dimension == other.dimension

    companion object {
        /**
         * 文字列から単位を検索する。
         * 見つからない場合はnullを返す。
         */
        fun fromSymbol(symbol: String): ComparisonUnit? =
            entries.find { it.symbol == symbol }
    }
}
