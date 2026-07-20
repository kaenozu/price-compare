import 'decimal.dart';

enum UnitDimension {
  weight,
  capacity,
  count,
}

enum ComparisonUnit {
  gram('g', UnitDimension.weight, '1'),
  kilogram('kg', UnitDimension.weight, '1000'),
  milliliter('ml', UnitDimension.capacity, '1'),
  liter('L', UnitDimension.capacity, '1000'),
  count('個', UnitDimension.count, '1');

  const ComparisonUnit(this.symbol, this.dimension, this._factor);

  final String symbol;
  final UnitDimension dimension;
  final String _factor;

  Decimal get conversionFactor => Decimal(_factor);

  ComparisonUnit get baseUnit => switch (dimension) {
        UnitDimension.weight => ComparisonUnit.gram,
        UnitDimension.capacity => ComparisonUnit.milliliter,
        UnitDimension.count => ComparisonUnit.count,
      };

  bool isSameDimension(ComparisonUnit other) =>
      dimension == other.dimension;
}
