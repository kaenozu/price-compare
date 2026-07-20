import 'decimal.dart';
import 'unit.dart';

class Quantity {
  final Decimal value;
  final ComparisonUnit unit;

  const Quantity({
    required this.value,
    required this.unit,
  });

  Quantity normalize() => Quantity(
        value: value * unit.conversionFactor,
        unit: unit.baseUnit,
      );

  bool isCompatibleWith(Quantity other) =>
      unit.isSameDimension(other.unit);

  @override
  String toString() => '${value.toPlainString()}${unit.symbol}';
}
