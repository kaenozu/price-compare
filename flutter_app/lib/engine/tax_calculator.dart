import 'decimal.dart';
import 'money.dart';
import 'rounding.dart';
import 'tax_mode.dart';

abstract final class TaxCalculator {
  static Money basePriceExcludingTax(
    Money price,
    TaxMode taxMode,
    Decimal taxRate,
  ) {
    if (taxMode == TaxMode.taxExcluded) {
      return price;
    }

    final divisor = Decimal.one + taxRate;
    final taxAmount = Rounding.roundMoney(price.amount * taxRate / divisor);
    return price - taxAmount;
  }

  static Money taxAmount(Money basePrice, Decimal taxRate) =>
      Rounding.roundMoney(basePrice.amount * taxRate);

  static Money priceIncludingTax(
    Money basePrice,
    Decimal taxRate, {
    Money? originalPrice,
  }) =>
      originalPrice ?? (basePrice + taxAmount(basePrice, taxRate));
}
