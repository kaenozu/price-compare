import 'decimal.dart';

class Money implements Comparable<Money> {
  final Decimal amount;

  const Money(this.amount);

  static final Money zero = Money(Decimal.zero);

  factory Money.of(String value) => Money(Decimal(value));

  factory Money.fromInt(int value) => Money(Decimal.fromInt(value));

  Money operator +(Money other) => Money(amount + other.amount);

  Money operator -(Money other) => Money(amount - other.amount);

  Money operator *(Decimal factor) => Money(amount * factor);

  Decimal operator /(Money other) => amount / other.amount;

  Money operator -() => Money(-amount);

  bool get isPositive => amount.isPositive;
  bool get isNegative => amount.isNegative;
  bool get isZero => amount.isZero;

  Money abs() => isNegative ? -this : this;

  @override
  int compareTo(Money other) => amount.compareTo(other.amount);

  @override
  String toString() => '${amount.toPlainString()}円';

  @override
  bool operator ==(Object other) => other is Money && amount == other.amount;

  @override
  int get hashCode => amount.hashCode;
}
