package com.pricecompare.comparison

/**
 * src/commonTest/kotlin/com/pricecompare/comparison/ComparisonEngineTest.kt
 *
 * ComparisonEngineの単体テスト。
 * 2商品比較のロジックを検証する。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/comparison/ComparisonEngine.kt
 * - src/commonMain/kotlin/com/pricecompare/model/ComparisonResult.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Offer.kt
 */
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ComparisonEngineTest {

    @Test
    fun testBasicComparison() {
        val offerA = createOffer("商品A", "1000", "TAX_INCLUDED", "0.1", "500", "g")
        val offerB = createOffer("商品B", "1200", "TAX_INCLUDED", "0.1", "600", "g")
        val context = createContext()

        val result = ComparisonEngine.compare(offerA, context, offerB, context)

        assertTrue(result.isComparable())
        assertEquals(0, result.cheapestByPayable) // Aが安い
        assertEquals(0, result.cheapestByEffective) // Aが安い
    }

    @Test
    fun testIdenticalItems() {
        val offerA = createOffer("商品A", "1000", "TAX_INCLUDED", "0.1", "500", "g")
        val offerB = createOffer("商品B", "1000", "TAX_INCLUDED", "0.1", "500", "g")
        val context = createContext()

        val result = ComparisonEngine.compare(offerA, context, offerB, context)

        assertTrue(result.isComparable())
        assertNull(result.cheapestByPayable) // 同額
    }

    @Test
    fun testIncompatibleDimensions() {
        val offerA = createOffer("商品A", "1000", "TAX_INCLUDED", "0.1", "500", "g")
        val offerB = createOffer("商品B", "1000", "TAX_INCLUDED", "0.1", "500", "ml")
        val context = createContext()

        val result = ComparisonEngine.compare(offerA, context, offerB, context)

        assertTrue(!result.isComparable())
        assertNotNull(result.incompatibilityReason)
    }

    @Test
    fun testPointsMakeEffectiveCostNegative() {
        val offerA = createOffer("商品A", "1000", "TAX_INCLUDED", "0.1", "500", "g")
        val offerB = createOffer("商品B", "1000", "TAX_INCLUDED", "0.1", "500", "g")
        val contextA = createContext(earnedPoints = 1500)
        val contextB = createContext()

        val result = ComparisonEngine.compare(offerA, contextA, offerB, contextB)

        assertTrue(result.isComparable())
        assertNotNull(result.breakdownA.effectiveCost)
        assertTrue(result.breakdownA.effectiveCost!!.isNegative())
    }

    @Test
    fun testUnitPriceComparison() {
        val offerA = createOffer("商品A", "500", "TAX_INCLUDED", "0.1", "500", "ml")
        val offerB = createOffer("商品B", "900", "TAX_INCLUDED", "0.1", "1000", "ml")
        val context = createContext()

        val result = ComparisonEngine.compare(offerA, context, offerB, context)

        assertTrue(result.isComparable())
        assertEquals(1, result.cheapestByUnitPrice) // Bの単位価格が安い
    }

    @Test
    fun testCapacityKgVsG() {
        val offerA = createOffer("商品A", "500", "TAX_INCLUDED", "0.1", "0.5", "kg")
        val offerB = createOffer("商品B", "600", "TAX_INCLUDED", "0.1", "500", "g")
        val context = createContext()

        val result = ComparisonEngine.compare(offerA, context, offerB, context)

        assertTrue(result.isComparable())
        assertEquals(0, result.cheapestByUnitPrice) // Aの単位価格が安い
    }

    @Test
    fun testCapacityLvsMl() {
        val offerA = createOffer("商品A", "500", "TAX_INCLUDED", "0.1", "1", "L")
        val offerB = createOffer("商品B", "600", "TAX_INCLUDED", "0.1", "1000", "ml")
        val context = createContext()

        val result = ComparisonEngine.compare(offerA, context, offerB, context)

        assertTrue(result.isComparable())
        assertEquals(1, result.cheapestByUnitPrice) // Bの単位価格が安い
    }

    @Test
    fun testCountUnit() {
        val offerA = createOffer("商品A", "100", "TAX_INCLUDED", "0.1", "10", "個")
        val offerB = createOffer("商品B", "180", "TAX_INCLUDED", "0.1", "20", "個")
        val context = createContext()

        val result = ComparisonEngine.compare(offerA, context, offerB, context)

        assertTrue(result.isComparable())
        assertEquals(0, result.cheapestByUnitPrice) // Aの単位価格が安い
    }

    // ヘルパー関数
    private fun createOffer(
        productName: String,
        price: String,
        taxMode: String,
        taxRate: String,
        quantity: String,
        unit: String
    ): com.pricecompare.model.Offer {
        return com.pricecompare.model.Offer(
            productName = productName,
            displayedPrice = Money.of(price),
            taxMode = when (taxMode) {
                "TAX_INCLUDED" -> com.pricecompare.model.TaxMode.TAX_INCLUDED
                "TAX_EXCLUDED" -> com.pricecompare.model.TaxMode.TAX_EXCLUDED
                else -> throw IllegalArgumentException("Unknown tax mode: $taxMode")
            },
            taxRate = Decimal(taxRate),
            quantity = com.pricecompare.model.Quantity(
                value = Decimal(quantity),
                unit = com.pricecompare.model.ComparisonUnit.fromSymbol(unit)
                    ?: throw IllegalArgumentException("Unknown unit: $unit")
            )
        )
    }

    private fun createContext(): com.pricecompare.model.PurchaseContext {
        return com.pricecompare.model.PurchaseContext()
    }
}
