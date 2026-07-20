package com.pricecompare.app.ui

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class PriceCompareViewModelTest {
    @Test
    fun compare_usesPhase1EngineAndReturnsCheapestProduct() {
        val viewModel = PriceCompareViewModel()

        viewModel.compare()

        val result = viewModel.uiState.value.result
        assertNotNull(result)
        assertEquals(0, result?.cheapestByPayable)
        assertEquals(0, result?.cheapestByEffective)
        assertEquals(0, result?.cheapestByUnitPrice)
    }

    @Test
    fun compare_invalidPriceKeepsInputScreenAndShowsError() {
        val viewModel = PriceCompareViewModel()
        viewModel.onDisplayedPriceChanged(ProductSlot.A, "invalid")

        viewModel.compare()

        assertNull(viewModel.uiState.value.result)
        assertEquals(
            "商品Aの表示価格は数値で入力してください。",
            viewModel.uiState.value.errorMessage,
        )
    }
}
