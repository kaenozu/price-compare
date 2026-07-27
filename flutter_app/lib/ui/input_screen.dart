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
              onChanged: notifier.updateInputA,
            ),
            const SizedBox(height: 16),
            _ProductInputCard(
              title: '商品B',
              input: state.inputB,
              onChanged: notifier.updateInputB,
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
    required this.onChanged,
  });

  final String title;
  final ProductInput input;
  final ValueChanged<ProductInput> onChanged;

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
          ],
        ),
      ),
    );
  }

  static String? _validateDecimal(
    String? value, {
    required String label,
    required bool allowZero,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$labelを入力してください';
    }
    try {
      final decimal = Decimal(value);
      if (allowZero ? decimal < Decimal.zero : decimal <= Decimal.zero) {
        return allowZero ? '$labelは0以上で入力してください' : '$labelは0より大きい値を入力してください';
      }
      return null;
    } on FormatException {
      return '$labelを数値で入力してください';
    }
  }

  static String? _validateTaxRate(String? value) {
    final basic = _validateDecimal(value, label: '税率', allowZero: true);
    if (basic != null) {
      return basic;
    }
    final rate = Decimal(value!);
    return rate > Decimal('100') ? '税率は100%以下で入力してください' : null;
  }
}
