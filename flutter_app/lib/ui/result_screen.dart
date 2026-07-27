import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/comparison_engine.dart';
import '../engine/price_breakdown.dart';
import '../engine/unit.dart';
import '../providers/price_compare_provider.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(priceCompareProvider);
    final result = state.result;

    return Scaffold(
      appBar: AppBar(title: const Text('比較結果')),
      body: result == null
          ? _NoResult(onBack: () => Navigator.of(context).pop())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _BreakdownCard(
                  title: '商品A',
                  breakdown: result.breakdownA,
                  unit: state.inputA.unit,
                ),
                const SizedBox(height: 16),
                _BreakdownCard(
                  title: '商品B',
                  breakdown: result.breakdownB,
                  unit: state.inputB.unit,
                ),
                const SizedBox(height: 16),
                _ComparisonCard(result: result),
                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '注意',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          for (final warning in result.warnings)
                            Text('• $warning'),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    ref.read(priceCompareProvider.notifier).clearResult();
                    Navigator.of(context).pop();
                  },
                  child: const Text('入力に戻る'),
                ),
              ],
            ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.breakdown,
    required this.unit,
  });

  final String title;
  final PriceBreakdown breakdown;
  final ComparisonUnit unit;

  @override
  Widget build(BuildContext context) {
    final unitPrice = breakdown.unitPrice;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ValueRow(label: 'お支払い額', value: breakdown.payableNow.toString()),
            _ValueRow(
              label: '実質負担額',
              value: breakdown.effectiveCost.toString(),
            ),
            _ValueRow(
              label: '単位価格',
              value: unitPrice == null
                  ? '計算不能'
                  : '${unitPrice.toPlainString()}円/100${unit.baseUnit.symbol}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.result});

  final ComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final reason = result.incompatibilityReason;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('どちらが安いか', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (reason != null)
              Text(
                reason,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else ...[
              _ValueRow(
                label: 'お支払い額',
                value:
                    '${_winnerLabel(result.cheapestByPayable)}（差額 ${result.payableDifference}）',
              ),
              _ValueRow(
                label: '実質負担額',
                value:
                    '${_winnerLabel(result.cheapestByEffective)}（差額 ${result.effectiveDifference}）',
              ),
              _ValueRow(
                label: '単位価格',
                value: _winnerLabel(result.cheapestByUnitPrice),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _winnerLabel(ComparisonWinner? winner) => switch (winner) {
        ComparisonWinner.productA => '商品A',
        ComparisonWinner.productB => '商品B',
        ComparisonWinner.tie => '同額',
        null => '比較不能',
      };
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 104, child: Text(label)),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

class _NoResult extends StatelessWidget {
  const _NoResult({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton(onPressed: onBack, child: const Text('入力に戻る')),
      );
}
