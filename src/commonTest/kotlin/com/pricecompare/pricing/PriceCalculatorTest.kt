package com.pricecompare.pricing

/**
 * src/commonTest/kotlin/com/pricecompare/pricing/PriceCalculatorTest.kt
 *
 * PriceCalculatorの単体テスト。
 * test_cases.jsonから期待値を読み込み、Kotlin実装と比較検証する。
 *
 * 関連ファイル:
 * - src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
 * - src/commonMain/kotlin/com/pricecompare/model/Offer.kt
 * - src/commonMain/kotlin/com/pricecompare/model/PurchaseContext.kt
 * - src/commonTest/resources/test_cases.json
 */
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class PriceCalculatorTest {

    @Test
    fun testSimpleTaxIncluded() {
        val offer = createOffer(
            productName = "テスト商品",
            price = "1000",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "500",
            unit = "g"
        )
        val context = createContext()

        val result = PriceCalculator.calculate(offer, context)

        assertNotNull(result.payableNow)
        assertEquals("1000", result.payableNow!!.amount.toPlainString())
    }

    @Test
    fun testTaxExcluded() {
        val offer = createOffer(
            productName = "テスト商品",
            price = "900",
            taxMode = "TAX_EXCLUDED",
            taxRate = "0.1",
            quantity = "500",
            unit = "g"
        )
        val context = createContext()

        val result = PriceCalculator.calculate(offer, context)

        assertNotNull(result.payableNow)
        assertEquals("990", result.payableNow!!.amount.toPlainString())
    }

    @Test
    fun testItemDiscountPercentage() {
        val offer = createOffer(
            productName = "テスト商品",
            price = "1000",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "500",
            unit = "g",
            discounts = listOf(mapOf("type" to "percentage", "rate" to "0.1"))
        )
        val context = createContext()

        val result = PriceCalculator.calculate(offer, context)

        assertNotNull(result.payableNow)
        assertEquals("900", result.payableNow!!.amount.toPlainString())
    }

    @Test
    fun testItemDiscountFixed() {
        val offer = createOffer(
            productName = "テスト商品",
            price = "1000",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "500",
            unit = "g",
            discounts = listOf(mapOf("type" to "fixed", "amount" to "100"))
        )
        val context = createContext()

        val result = PriceCalculator.calculate(offer, context)

        assertNotNull(result.payableNow)
        assertEquals("900", result.payableNow!!.amount.toPlainString())
    }

    @Test
    fun testShippingCost() {
        val offer = createOffer(
            productName = "テスト商品",
            price = "1000",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "500",
            unit = "g"
        )
        val context = createContext(shipping = "500")

        val result = PriceCalculator.calculate(offer, context)

        assertNotNull(result.payableNow)
        assertEquals("1500", result.payableNow!!.amount.toPlainString())
    }

    @Test
    fun testFreeShippingThreshold() {
        val offer = createOffer(
            productName = "テスト商品",
            price = "3000",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "1",
            unit = "個"
        )
        val context = createContext(shipping = "500", threshold = "3000")

        val result = PriceCalculator.calculate(offer, context)

        assertNotNull(result.payableNow)
        assertEquals("0", result.shippingCost!!.amount.toPlainString())
        assertEquals("3000", result.payableNow!!.amount.toPlainString())
    }

    @Test
    fun testPointsEarned() {
        val offer = createOffer(
            productName = "テスト商品",
            price = "1000",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "500",
            unit = "g"
        )
        val context = createContext(earnedPoints = 100)

        val result = PriceCalculator.calculate(offer, context)

        assertNotNull(result.payableNow)
        assertEquals("1000", result.payableNow!!.amount.toPlainString())
        assertEquals("100", result.earnedPointsValue.amount.toPlainString())
        assertNotNull(result.effectiveCost)
        assertEquals("900", result.effectiveCost!!.amount.toPlainString())
    }

    @Test
    fun testPointsUsed() {
        val offer = createOffer(
            productName = "テスト商品",
            price = "1000",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "500",
            unit = "g"
        )
        val context = createContext(usedPoints = 500)

        val result = PriceCalculator.calculate(offer, context)

        assertNotNull(result.payableNow)
        assertEquals("500", result.payableNow!!.amount.toPlainString())
    }

    @Test
    fun testUnitPriceCalculation() {
        val offer = createOffer(
            productName = "テスト商品",
            price = "1000",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "500",
            unit = "g"
        )
        val context = createContext()

        val result = PriceCalculator.calculate(offer, context)

        assertNotNull(result.unitPrice)
        // 1000円 / 500g * 100 = 200円/100g
        assertEquals("200", result.unitPrice!!.toPlainString())
    }

    @Test
    fun testCapacityDifference() {
        val offerA = createOffer(
            productName = "商品A",
            price = "500",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "500",
            unit = "ml"
        )
        val offerB = createOffer(
            productName = "商品B",
            price = "900",
            taxMode = "TAX_INCLUDED",
            taxRate = "0.1",
            quantity = "1",
            unit = "L"
        )
        val contextA = createContext()
        val contextB = createContext()

        val resultA = PriceCalculator.calculate(offerA, contextA)
        val resultB = PriceCalculator.calculate(offerB, contextB)

        assertNotNull(resultA.unitPrice)
        assertNotNull(resultB.unitPrice)
        // 商品A: 500円 / 500ml * 100 = 100円/100ml
        assertEquals("100", resultA.unitPrice!!.toPlainString())
        // 商品B: 900円 / 1000ml * 100 = 90円/100ml
        assertEquals("90", resultB.unitPrice!!.toPlainString())
    }

    // ヘルパー関数
    private fun createOffer(
        productName: String,
        price: String,
        taxMode: String,
        taxRate: String,
        quantity: String,
        unit: String,
        discounts: List<Map<String, Any>> = emptyList()
    ): com.pricecompare.model.Offer {
        val parsedDiscounts = discounts.map { d ->
            when (d["type"]) {
                "percentage" -> com.pricecompare.model.Discount.PercentageDiscount(
                    Decimal(d["rate"] as String)
                )
                "fixed" -> com.pricecompare.model.Discount.FixedAmount(
                    Money.of(d["amount"] as String)
                )
                else -> throw IllegalArgumentException("Unknown discount type: ${d["type"]}")
            }
        }

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
            ),
            discounts = parsedDiscounts
        )
    }

    private fun createContext(
        shipping: String? = null,
        threshold: String? = null,
        coupons: List<Map<String, Any>> = emptyList(),
        usedPoints: Int = 0,
        earnedPoints: Int = 0,
        pointRate: String = "1.0"
    ): com.pricecompare.model.PurchaseContext {
        val parsedCoupons = coupons.map { c ->
            com.pricecompare.model.Discount.CouponDiscount(
                amount = Money.of(c["amount"].toString()),
                name = c["name"] as String? ?: ""
            )
        }

        return com.pricecompare.model.PurchaseContext(
            shippingCost = if (shipping != null) Money.of(shipping) else null,
            freeShippingThreshold = if (threshold != null) Money.of(threshold) else null,
            orderCoupons = parsedCoupons,
            usedPoints = usedPoints,
            earnedPoints = earnedPoints,
            pointEvaluationRate = Decimal(pointRate)
        )
    }
}
