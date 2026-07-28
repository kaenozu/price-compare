import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/decimal.dart';
import '../engine/tax_mode.dart';
import '../engine/unit.dart';
import '../providers/price_compare_provider.dart';

class InputScreen extends ConsumerStatefulWidget {
  const InputScreen({super.key});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceCompareProvider);
    final notifier = ref.read(priceCompareProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('価格比較')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProductInputCard(
              title: '商品A',
              input: state.inputA,
              purchaseContext: state.contextA,
              onChanged: notifier.updateInputA,
              onPurchaseContextChanged: notifier.updateContextA,
            ),
            const SizedBox(height: 16),
            _ProductInputCard(
              title: '商品B',
              input: state.inputB,
              purchaseContext: state.contextB,
              onChanged: notifier.updateInputB,
              onPurchaseContextChanged: notifier.updateContextB,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _compare(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('比較する'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _compare(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final notifier = ref.read(priceCompareProvider.notifier);
    if (notifier.compare()) {
      Navigator.of(context).pushNamed('/result');
      return;
    }

    final message =
        ref.read(priceCompareProvider).errorMessage ?? '入力内容を確認してください';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProductInputCard extends StatelessWidget {
  const _ProductInputCard({
    required this.title,
    required this.input,
    required this.purchaseContext,
    required this.onChanged,
    required this.onPurchaseContextChanged,
  });

  final String title;
  final ProductInput input;
  final PurchaseContextInput purchaseContext;
  final ValueChanged<ProductInput> onChanged;
  final ValueChanged<PurchaseContextInput> onPurchaseContextChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: input.displayedPrice,
              decoration: const InputDecoration(
                labelText: '表示価格',
                suffixText: '円',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  _validateDecimal(value, label: '表示価格', allowZero: true),
              onChanged: (value) =>
                  onChanged(input.copyWith(displayedPrice: value)),
            ),
            const SizedBox(height: 16),
            Text('価格表示', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('税込'),
                  selected: input.taxMode == TaxMode.taxIncluded,
                  onSelected: (_) =>
                      onChanged(input.copyWith(taxMode: TaxMode.taxIncluded)),
                ),
                FilterChip(
                  label: const Text('税抜'),
                  selected: input.taxMode == TaxMode.taxExcluded,
                  onSelected: (_) =>
                      onChanged(input.copyWith(taxMode: TaxMode.taxExcluded)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: input.taxRatePercent,
              decoration: const InputDecoration(
                labelText: '税率',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validateTaxRate,
              onChanged: (value) =>
                  onChanged(input.copyWith(taxRatePercent: value)),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: input.quantity,
                    decoration: const InputDecoration(
                      labelText: '数量・容量',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        _validateDecimal(value, label: '数量', allowZero: false),
                    onChanged: (value) =>
                        onChanged(input.copyWith(quantity: value)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 112,
                  child: DropdownButtonFormField<ComparisonUnit>(
                    initialValue: input.unit,
                    decoration: const InputDecoration(
                      labelText: '単位',
                      border: OutlineInputBorder(),
                    ),
                    items: ComparisonUnit.values
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.symbol),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (unit) {
                      if (unit != null) {
                        onChanged(input.copyWith(unit: unit));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: input.discountValue,
                    decoration: InputDecoration(
                      labelText: input.discountIsPercent ? '割引率' : '割引額',
                      suffixText: input.discountIsPercent ? '%' : '円',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => _validateOptionalDecimal(
                      value,
                      label: input.discountIsPercent ? '割引率' : '割引額',
                      maximum: input.discountIsPercent ? Decimal('100') : null,
                    ),
                    onChanged: (value) =>
                        onChanged(input.copyWith(discountValue: value)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('定額')),
                      ButtonSegment(value: true, label: Text('％')),
                    ],
                    selected: {input.discountIsPercent},
                    onSelectionChanged: (selected) => onChanged(
                      input.copyWith(
                        discountIsPercent: selected.first,
                        discountValue: '',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PurchaseContextSection(
              input: purchaseContext,
              onChanged: onPurchaseContextChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseContextSection extends StatelessWidget {
  const _PurchaseContextSection({
    required this.input,
    required this.onChanged,
  });

  final PurchaseContextInput input;
  final ValueChanged<PurchaseContextInput> onChanged;

  String _subtitle() {
    final parts = <String>[];
    if (input.shippingCost.isNotEmpty) {
      parts.add('送料 ${input.shippingCost}円');
    }
    if (input.couponAmount.isNotEmpty) {
      parts.add('クーポン ${input.couponAmount}円');
    }
    if (input.usedPoints.isNotEmpty) {
      parts.add('使用 ${input.usedPoints}pt');
    }
    if (input.earnedPoints.isNotEmpty) {
      parts.add('獲得 ${input.earnedPoints}pt');
    }
    return parts.isEmpty ? '未設定' : parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: const Text('送料・クーポン・ポイント'),
        subtitle: Text(_subtitle()),
        initiallyExpanded: input.hasAny,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextFormField(
              initialValue: input.shippingCost,
              decoration: const InputDecoration(
                labelText: '送料',
                helperText: '不明な場合は空欄のまま比較できます',
                suffixText: '円',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  _validateOptionalDecimal(value, label: '送料'),
              onChanged: (value) =>
                  onChanged(input.copyWith(shippingCost: value)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextFormField(
              initialValue: input.couponAmount,
              decoration: const InputDecoration(
                labelText: 'クーポン割引',
                suffixText: '円',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  _validateOptionalDecimal(value, label: 'クーポン'),
              onChanged: (value) =>
                  onChanged(input.copyWith(couponAmount: value)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextFormField(
              initialValue: input.usedPoints,
              decoration: const InputDecoration(
                labelText: '使用ポイント',
                suffixText: 'pt',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  _validateOptionalPoints(value, label: '使用ポイント'),
              onChanged: (value) =>
                  onChanged(input.copyWith(usedPoints: value)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextFormField(
              initialValue: input.earnedPoints,
              decoration: const InputDecoration(
                labelText: '獲得ポイント',
                suffixText: 'pt',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  _validateOptionalPoints(value, label: '獲得ポイント'),
              onChanged: (value) =>
                  onChanged(input.copyWith(earnedPoints: value)),
            ),
          ),
        ],
      ),
    );
  }
}

String? _validateDecimal(
  String? value, {
  required String label,
  required bool allowZero,
}) {
  if (value == null || value.trim().isEmpty) {
    return '$labelを入力してください';
  }
  try {
    final decimal = Decimal(value.trim());
    if (allowZero ? decimal < Decimal.zero : decimal <= Decimal.zero) {
      return allowZero
          ? '$labelは0以上で入力してください'
          : '$labelは0より大きい値を入力してください';
    }
    return null;
  } on FormatException {
    return '$labelを数値で入力してください';
  }
}

String? _validateTaxRate(String? value) {
  final basic = _validateDecimal(value, label: '税率', allowZero: true);
  if (basic != null) return basic;
  final rate = Decimal(value!.trim());
  return rate > Decimal('100') ? '税率は100%以下で入力してください' : null;
}

String? _validateOptionalDecimal(
  String? value, {
  required String label,
  Decimal? maximum,
}) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    final decimal = Decimal(value.trim());
    if (decimal < Decimal.zero) return '$labelは0以上で入力してください';
    if (maximum != null && decimal > maximum) {
      return '$labelは${maximum.toPlainString()}以下で入力してください';
    }
    return null;
  } on FormatException {
    return '$labelを数値で入力してください';
  }
}

String? _validateOptionalPoints(String? value, {required String label}) {
  if (value == null || value.trim().isEmpty) return null;
  final points = int.tryParse(value.trim());
  if (points == null || points < 0) {
    return '$labelは0以上の整数で入力してください';
  }
  return null;
}
