class Decimal implements Comparable<Decimal> {
  static const int defaultDivisionScale = 10;

  final BigInt _unscaled;
  final int scale;

  factory Decimal(String value) {
    final input = value.trim();
    final match =
        RegExp(r'^([+-]?)(\d*)(?:\.(\d*))?$').firstMatch(input);
    if (match == null) {
      throw FormatException('Invalid decimal: $value');
    }

    final sign = match.group(1) == '-' ? -1 : 1;
    final integerPart = match.group(2) ?? '';
    final fractionalPart = match.group(3) ?? '';
    if (integerPart.isEmpty && fractionalPart.isEmpty) {
      throw FormatException('Invalid decimal: $value');
    }

    final digits =
        '${integerPart.isEmpty ? '0' : integerPart}$fractionalPart';
    final unscaled = BigInt.parse(digits) * BigInt.from(sign);
    return Decimal.fromUnscaled(unscaled, fractionalPart.length);
  }

  factory Decimal.fromInt(int value) =>
      Decimal.fromUnscaled(BigInt.from(value), 0);

  factory Decimal.fromBigInt(BigInt value) =>
      Decimal.fromUnscaled(value, 0);

  factory Decimal.fromUnscaled(BigInt unscaled, int scale) {
    if (scale < 0) {
      throw ArgumentError.value(scale, 'scale', 'must be non-negative');
    }

    var normalized = unscaled;
    var normalizedScale = scale;
    while (normalizedScale > 0 &&
        normalized.remainder(BigInt.from(10)) == BigInt.zero) {
      normalized ~/= BigInt.from(10);
      normalizedScale--;
    }
    return Decimal._(normalized, normalizedScale);
  }

  const Decimal._(this._unscaled, this.scale);

  static final Decimal zero = Decimal('0');
  static final Decimal one = Decimal('1');

  BigInt get unscaledValue => _unscaled;

  Decimal operator +(Decimal other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    final left = _unscaled * _pow10(targetScale - scale);
    final right = other._unscaled * _pow10(targetScale - other.scale);
    return Decimal.fromUnscaled(left + right, targetScale);
  }

  Decimal operator -(Decimal other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    final left = _unscaled * _pow10(targetScale - scale);
    final right = other._unscaled * _pow10(targetScale - other.scale);
    return Decimal.fromUnscaled(left - right, targetScale);
  }

  Decimal operator *(Decimal other) =>
      Decimal.fromUnscaled(_unscaled * other._unscaled, scale + other.scale);

  Decimal operator /(Decimal other) =>
      divide(other, resultScale: defaultDivisionScale);

  Decimal operator -() => Decimal.fromUnscaled(-_unscaled, scale);

  Decimal divide(Decimal other, {int resultScale = defaultDivisionScale}) {
    if (other.isZero) {
      throw ArgumentError('Division by zero');
    }
    if (resultScale < 0) {
      throw ArgumentError.value(
        resultScale,
        'resultScale',
        'must be non-negative',
      );
    }

    final numerator =
        _unscaled * _pow10(other.scale + resultScale);
    final denominator = other._unscaled * _pow10(scale);
    final quotient = _divideHalfUp(numerator, denominator);
    return Decimal.fromUnscaled(quotient, resultScale);
  }

  Decimal abs() => isNegative ? -this : this;

  bool get isZero => _unscaled == BigInt.zero;
  bool get isPositive => _unscaled > BigInt.zero;
  bool get isNegative => _unscaled < BigInt.zero;

  Decimal stripTrailingZeros() => this;

  String toPlainString() {
    if (scale == 0) {
      return _unscaled.toString();
    }

    final negative = _unscaled.isNegative;
    final digits = _unscaled.abs().toString().padLeft(scale + 1, '0');
    final splitIndex = digits.length - scale;
    final integerPart = digits.substring(0, splitIndex);
    final fractionalPart = digits.substring(splitIndex);
    return '${negative ? '-' : ''}$integerPart.$fractionalPart';
  }

  @override
  int compareTo(Decimal other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    final left = _unscaled * _pow10(targetScale - scale);
    final right = other._unscaled * _pow10(targetScale - other.scale);
    return left.compareTo(right);
  }

  bool operator <(Decimal other) => compareTo(other) < 0;
  bool operator <=(Decimal other) => compareTo(other) <= 0;
  bool operator >(Decimal other) => compareTo(other) > 0;
  bool operator >=(Decimal other) => compareTo(other) >= 0;

  @override
  String toString() => toPlainString();

  @override
  bool operator ==(Object other) =>
      other is Decimal &&
      _unscaled == other._unscaled &&
      scale == other.scale;

  @override
  int get hashCode => Object.hash(_unscaled, scale);

  static BigInt _pow10(int exponent) => BigInt.from(10).pow(exponent);

  static BigInt _divideHalfUp(BigInt numerator, BigInt denominator) {
    final negative = numerator.isNegative != denominator.isNegative;
    final absoluteNumerator = numerator.abs();
    final absoluteDenominator = denominator.abs();
    var quotient = absoluteNumerator ~/ absoluteDenominator;
    final remainder = absoluteNumerator.remainder(absoluteDenominator);

    if (remainder * BigInt.from(2) >= absoluteDenominator) {
      quotient += BigInt.one;
    }
    return negative ? -quotient : quotient;
  }
}
