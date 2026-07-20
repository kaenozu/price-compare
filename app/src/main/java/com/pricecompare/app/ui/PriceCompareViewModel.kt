package com.pricecompare.app.ui

import androidx.lifecycle.ViewModel
import com.pricecompare.comparison.ComparisonEngine
import com.pricecompare.model.ComparisonResult
import com.pricecompare.model.ComparisonUnit
import com.pricecompare.model.Decimal
import com.pricecompare.model.Money
import com.pricecompare.model.Offer
import com.pricecompare.model.PurchaseContext
import com.pricecompare.model.Quantity
import com.pricecompare.model.TaxMode
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

enum class ProductSlot {
    A,
    B,
}

data class ProductInputState(
    val displayedPrice: String,
    val taxMode: TaxMode,
    val taxRatePercent: String,
    val quantity: String,
    val unit: ComparisonUnit,
)

data class PriceCompareUiState(
    val productA: ProductInputState = ProductInputState(
        displayedPrice = "198",
        taxMode = TaxMode.TAX_INCLUDED,
        taxRatePercent = "8",
        quantity = "500",
        unit = ComparisonUnit.GRAM,
    ),
    val productB: ProductInputState = ProductInputState(
        displayedPrice = "248",
        taxMode = TaxMode.TAX_INCLUDED,
        taxRatePercent = "8",
        quantity = "600",
        unit = ComparisonUnit.GRAM,
    ),
    val result: ComparisonResult? = null,
    val errorMessage: String? = null,
)

class PriceCompareViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(PriceCompareUiState())
    val uiState: StateFlow<PriceCompareUiState> = _uiState.asStateFlow()

    fun onDisplayedPriceChanged(slot: ProductSlot, value: String) {
        updateProduct(slot) { it.copy(displayedPrice = value) }
    }

    fun onTaxModeChanged(slot: ProductSlot, value: TaxMode) {
        updateProduct(slot) { it.copy(taxMode = value) }
    }

    fun onTaxRateChanged(slot: ProductSlot, value: String) {
        updateProduct(slot) { it.copy(taxRatePercent = value) }
    }

    fun onQuantityChanged(slot: ProductSlot, value: String) {
        updateProduct(slot) { it.copy(quantity = value) }
    }

    fun onUnitChanged(slot: ProductSlot, value: ComparisonUnit) {
        updateProduct(slot) { it.copy(unit = value) }
    }

    fun compare() {
        try {
            val state = _uiState.value
            val offerA = state.productA.toOffer("商品A")
            val offerB = state.productB.toOffer("商品B")
            val context = PurchaseContext(shippingCost = Money.ZERO)

            val result = ComparisonEngine.compare(
                offerA = offerA,
                contextA = context,
                offerB = offerB,
                contextB = context,
            )

            _uiState.value = state.copy(
                result = result,
                errorMessage = null,
            )
        } catch (error: IllegalArgumentException) {
            _uiState.value = _uiState.value.copy(
                result = null,
                errorMessage = error.message ?: "入力内容を確認してください。",
            )
        } catch (_: Exception) {
            _uiState.value = _uiState.value.copy(
                result = null,
                errorMessage = "比較計算に失敗しました。入力内容を確認してください。",
            )
        }
    }

    fun editInputs() {
        _uiState.value = _uiState.value.copy(result = null)
    }

    private fun updateProduct(
        slot: ProductSlot,
        transform: (ProductInputState) -> ProductInputState,
    ) {
        val current = _uiState.value
        _uiState.value = when (slot) {
            ProductSlot.A -> current.copy(
                productA = transform(current.productA),
                result = null,
                errorMessage = null,
            )

            ProductSlot.B -> current.copy(
                productB = transform(current.productB),
                result = null,
                errorMessage = null,
            )
        }
    }

    private fun ProductInputState.toOffer(productName: String): Offer {
        val price = parseDecimal(displayedPrice, "$productNameの表示価格", allowZero = false)
        val taxPercent = parseDecimal(taxRatePercent, "$productNameの税率", allowZero = true)
        require(taxPercent.compareTo(Decimal("100")) <= 0) {
            "$productNameの税率は0〜100で入力してください。"
        }
        val quantityValue = parseDecimal(quantity, "$productNameの数量", allowZero = false)

        return Offer(
            productName = productName,
            displayedPrice = Money(price),
            taxMode = taxMode,
            taxRate = taxPercent / Decimal("100"),
            quantity = Quantity(quantityValue, unit),
        )
    }

    private fun parseDecimal(
        rawValue: String,
        fieldName: String,
        allowZero: Boolean,
    ): Decimal {
        val normalized = rawValue.trim()
        require(normalized.isNotEmpty()) { "$fieldNameを入力してください。" }

        val value = try {
            Decimal(normalized)
        } catch (_: Exception) {
            throw IllegalArgumentException("$fieldNameは数値で入力してください。")
        }

        val comparedToZero = value.compareTo(Decimal.ZERO)
        require(if (allowZero) comparedToZero >= 0 else comparedToZero > 0) {
            if (allowZero) {
                "$fieldNameは0以上で入力してください。"
            } else {
                "$fieldNameは0より大きい値を入力してください。"
            }
        }
        return value
    }
}
