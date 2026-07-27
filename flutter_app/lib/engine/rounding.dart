import 'decimal.dart';
import 'money.dart';

abstract final class Rounding {
  static Money roundMoney(Decimal value) =>
      Money(_roundHalfUp(value, fractionDigits: 0));

  static Decimal roundUnitPrice(Decimal value) =>
      _roundHalfUp(value, fractionDigits: 6);

  static Decimal _roundHalfUp(Decimal value, {required int fractionDigits}) {
    if (fractionDigits < 0) {
      throw ArgumentError.value(
        fractionDigits,
        'fractionDigits',
        'must be non-negative',
      );
    }
    if (value.scale <= fractionDigits) {
      return value;
    }

    final droppedDigits = value.scale - fractionDigits;
    final divisor = BigInt.from(10).pow(droppedDigits);
    final absolute = value.unscaledValue.abs();
    var quotient = absolute ~/ divisor;
    final remainder = absolute.remainder(divisor);

    if (remainder * BigInt.from(2) >= divisor) {
      quotient += BigInt.one;
    }
    if (value.unscaledValue.isNegative) {
      quotient = -quotient;
    }
    return Decimal.fromUnscaled(quotient, fractionDigits);
  }
}
