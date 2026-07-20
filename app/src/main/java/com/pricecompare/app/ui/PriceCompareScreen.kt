package com.pricecompare.app.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.weight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.pricecompare.model.ComparisonResult
import com.pricecompare.model.ComparisonUnit
import com.pricecompare.model.PriceBreakdown
import com.pricecompare.model.TaxMode

@Composable
fun PriceCompareRoute(
    viewModel: PriceCompareViewModel = viewModel(),
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    PriceCompareScreen(
        uiState = uiState,
        onDisplayedPriceChanged = viewModel::onDisplayedPriceChanged,
        onTaxModeChanged = viewModel::onTaxModeChanged,
        onTaxRateChanged = viewModel::onTaxRateChanged,
        onQuantityChanged = viewModel::onQuantityChanged,
        onUnitChanged = viewModel::onUnitChanged,
        onCompare = viewModel::compare,
        onEditInputs = viewModel::editInputs,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PriceCompareScreen(
    uiState: PriceCompareUiState,
    onDisplayedPriceChanged: (ProductSlot, String) -> Unit,
    onTaxModeChanged: (ProductSlot, TaxMode) -> Unit,
    onTaxRateChanged: (ProductSlot, String) -> Unit,
    onQuantityChanged: (ProductSlot, String) -> Unit,
    onUnitChanged: (ProductSlot, ComparisonUnit) -> Unit,
    onCompare: () -> Unit,
    onEditInputs: () -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(title = { Text("価格比較") })
        },
    ) { contentPadding ->
        val result = uiState.result
        if (result == null) {
            InputContent(
                modifier = Modifier.padding(contentPadding),
                uiState = uiState,
                onDisplayedPriceChanged = onDisplayedPriceChanged,
                onTaxModeChanged = onTaxModeChanged,
                onTaxRateChanged = onTaxRateChanged,
                onQuantityChanged = onQuantityChanged,
                onUnitChanged = onUnitChanged,
                onCompare = onCompare,
            )
        } else {
            ResultContent(
                modifier = Modifier.padding(contentPadding),
                uiState = uiState,
                result = result,
                onEditInputs = onEditInputs,
            )
        }
    }
}

@Composable
private fun InputContent(
    modifier: Modifier,
    uiState: PriceCompareUiState,
    onDisplayedPriceChanged: (ProductSlot, String) -> Unit,
    onTaxModeChanged: (ProductSlot, TaxMode) -> Unit,
    onTaxRateChanged: (ProductSlot, String) -> Unit,
    onQuantityChanged: (ProductSlot, String) -> Unit,
    onUnitChanged: (ProductSlot, ComparisonUnit) -> Unit,
    onCompare: () -> Unit,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        ProductInputCard(
            title = "商品A",
            input = uiState.productA,
            slot = ProductSlot.A,
            onDisplayedPriceChanged = onDisplayedPriceChanged,
            onTaxModeChanged = onTaxModeChanged,
            onTaxRateChanged = onTaxRateChanged,
            onQuantityChanged = onQuantityChanged,
            onUnitChanged = onUnitChanged,
        )

        ProductInputCard(
            title = "商品B",
            input = uiState.productB,
            slot = ProductSlot.B,
            onDisplayedPriceChanged = onDisplayedPriceChanged,
            onTaxModeChanged = onTaxModeChanged,
            onTaxRateChanged = onTaxRateChanged,
            onQuantityChanged = onQuantityChanged,
            onUnitChanged = onUnitChanged,
        )

        uiState.errorMessage?.let { message ->
            Text(
                text = message,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodyMedium,
            )
        }

        Button(
            onClick = onCompare,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("比較する")
        }
    }
}

@Composable
private fun ProductInputCard(
    title: String,
    input: ProductInputState,
    slot: ProductSlot,
    onDisplayedPriceChanged: (ProductSlot, String) -> Unit,
    onTaxModeChanged: (ProductSlot, TaxMode) -> Unit,
    onTaxRateChanged: (ProductSlot, String) -> Unit,
    onQuantityChanged: (ProductSlot, String) -> Unit,
    onUnitChanged: (ProductSlot, ComparisonUnit) -> Unit,
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
            )

            OutlinedTextField(
                value = input.displayedPrice,
                onValueChange = { onDisplayedPriceChanged(slot, it) },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("表示価格（円）") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            )

            Text(
                text = "価格区分",
                style = MaterialTheme.typography.labelLarge,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = input.taxMode == TaxMode.TAX_INCLUDED,
                    onClick = { onTaxModeChanged(slot, TaxMode.TAX_INCLUDED) },
                    label = { Text("税込") },
                )
                FilterChip(
                    selected = input.taxMode == TaxMode.TAX_EXCLUDED,
                    onClick = { onTaxModeChanged(slot, TaxMode.TAX_EXCLUDED) },
                    label = { Text("税抜") },
                )
            }

            OutlinedTextField(
                value = input.taxRatePercent,
                onValueChange = { onTaxRateChanged(slot, it) },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("税率（%）") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedTextField(
                    value = input.quantity,
                    onValueChange = { onQuantityChanged(slot, it) },
                    modifier = Modifier.weight(1f),
                    label = { Text("数量") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                )
                UnitSelector(
                    selectedUnit = input.unit,
                    onUnitChanged = { onUnitChanged(slot, it) },
                )
            }
        }
    }
}

@Composable
private fun UnitSelector(
    selectedUnit: ComparisonUnit,
    onUnitChanged: (ComparisonUnit) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }

    Box {
        OutlinedButton(onClick = { expanded = true }) {
            Text(selectedUnit.symbol)
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
        ) {
            ComparisonUnit.entries.forEach { unit ->
                DropdownMenuItem(
                    text = { Text(unit.symbol) },
                    onClick = {
                        expanded = false
                        onUnitChanged(unit)
                    },
                )
            }
        }
    }
}

@Composable
private fun ResultContent(
    modifier: Modifier,
    uiState: PriceCompareUiState,
    result: ComparisonResult,
    onEditInputs: () -> Unit,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(
            text = "比較結果",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
        )

        BreakdownCard(
            title = "商品A",
            breakdown = result.breakdownA,
            unit = uiState.productA.unit,
        )
        BreakdownCard(
            title = "商品B",
            breakdown = result.breakdownB,
            unit = uiState.productB.unit,
        )

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text(
                    text = "どちらが安いか",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )

                if (!result.isComparable()) {
                    Text(
                        text = result.incompatibilityReason ?: "単位価格を比較できません。",
                        color = MaterialTheme.colorScheme.error,
                    )
                } else {
                    ComparisonLine(
                        label = "お支払い額",
                        winner = winnerText(result.cheapestByPayable),
                        difference = "差 ${result.payableDifference.amount.toPlainString()}円",
                    )
                    ComparisonLine(
                        label = "実質負担額",
                        winner = winnerText(result.cheapestByEffective),
                        difference = "差 ${result.effectiveDifference.amount.toPlainString()}円",
                    )
                    ComparisonLine(
                        label = "単位価格",
                        winner = winnerText(result.cheapestByUnitPrice),
                        difference = null,
                    )
                }
            }
        }

        result.warnings.forEach { warning ->
            Text(
                text = warning,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
            )
        }

        Button(
            onClick = onEditInputs,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("入力に戻る")
        }
    }
}

@Composable
private fun BreakdownCard(
    title: String,
    breakdown: PriceBreakdown,
    unit: ComparisonUnit,
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
            )
            ResultValue("お支払い額", "${breakdown.payableNow.amount.toPlainString()}円")
            ResultValue("実質負担額", "${breakdown.effectiveCost.amount.toPlainString()}円")
            ResultValue(
                label = "単位価格",
                value = breakdown.unitPrice?.let {
                    "${it.toPlainString()}円 / 100${unit.baseUnit().symbol}"
                } ?: "計算不可",
            )
        }
    }
}

@Composable
private fun ResultValue(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Text(text = label, modifier = Modifier.weight(1f))
        Text(text = value, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun ComparisonLine(
    label: String,
    winner: String,
    difference: String?,
) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(text = label, modifier = Modifier.weight(1f))
            Text(text = winner, fontWeight = FontWeight.Bold)
        }
        difference?.let {
            Text(text = it, style = MaterialTheme.typography.bodySmall)
        }
        Spacer(modifier = Modifier.height(2.dp))
        HorizontalDivider()
    }
}

private fun winnerText(index: Int?): String = when (index) {
    0 -> "商品Aが安い"
    1 -> "商品Bが安い"
    else -> "同額"
}
