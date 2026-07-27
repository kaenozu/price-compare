import 'decimal.dart';
import 'money.dart';
import 'quantity.dart';
import 'rounding.dart';

abstract final class UnitNormalizer {
  static Quantity normalizeQuantity(Quantity quantity) => quantity.normalize();

  static bool areComparable(Quantity quantityA, Quantity quantityB) =>
      quantityA.isCompatibleWith(quantityB);

  static Decimal? calculateUnitPrice({
    required Money price,
    required Quantity quantity,
    int displayPer = 100,
  }) {
    final normalized = normalizeQuantity(quantity);
    if (normalized.value <= Decimal.zero) {
      return null;
    }

    final factor = Decimal.fromInt(displayPer);
    final unitPrice = (price.amount * factor) / normalized.value;
    return Rounding.roundUnitPrice(unitPrice);
  }
}
