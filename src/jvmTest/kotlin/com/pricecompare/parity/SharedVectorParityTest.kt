package com.pricecompare.parity

import com.pricecompare.model.ComparisonUnit
import com.pricecompare.model.Decimal
import com.pricecompare.model.Money
import com.pricecompare.model.Offer
import com.pricecompare.model.PurchaseContext
import com.pricecompare.model.Quantity
import com.pricecompare.model.TaxMode
import com.pricecompare.pricing.PriceCalculator
import java.io.File
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals

class SharedVectorParityTest {
    @Test
    fun sharedVectorsMatchKotlinEngine() {
        val cases = Json.parseToJsonElement(
            File("test_vectors/price_breakdown_cases.json").readText()
        ).jsonArray

        for (element in cases) {
            val case = element.jsonObject
            val name = case.string("name")
            val offer = Offer(
                productName = name,
                displayedPrice = Money.of(case.string("displayedPrice")),
                taxMode = when (case.string("taxMode")) {
                    "included" -> TaxMode.TAX_INCLUDED
                    "excluded" -> TaxMode.TAX_EXCLUDED
                    else -> error("Unknown tax mode in $name")
                },
                taxRate = Decimal(case.string("taxRate")),
                quantity = Quantity(
                    value = Decimal(case.string("quantity")),
                    unit = ComparisonUnit.fromSymbol(case.string("unit"))
                        ?: error("Unknown unit in $name")
                )
            )
            val context = PurchaseContext(
                shippingCost = Money.of(case.string("shippingCost")),
                usedPoints = case.int("usedPoints"),
                earnedPoints = case.int("earnedPoints"),
                pointEvaluationRate = Decimal(case.string("pointEvaluationRate"))
            )

            val result = PriceCalculator.calculate(offer, context)

            assertEquals(
                case.string("expectedPayableNow"),
                result.payableNow?.amount?.toPlainString(),
                "$name payableNow"
            )
            assertEquals(
                case.string("expectedEffectiveCost"),
                result.effectiveCost?.amount?.toPlainString(),
                "$name effectiveCost"
            )
            assertEquals(
                case.string("expectedUnitPrice"),
                result.unitPrice?.toPlainString(),
                "$name unitPrice"
            )
        }
    }

    private fun JsonObject.string(key: String): String =
        getValue(key).jsonPrimitive.content

    private fun JsonObject.int(key: String): Int =
        getValue(key).jsonPrimitive.content.toInt()
}
