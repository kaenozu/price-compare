import 'decimal.dart';
import 'money.dart';
import 'quantity.dart';
import 'tax_mode.dart';

sealed class Discount {
  const Discount();

  Money calculateAmount(Money baseAmount);
}

final class FixedAmountDiscount extends Discount {
  final Money amount;

  const FixedAmountDiscount(this.amount);

  @override
  Money calculateAmount(Money baseAmount) => amount;
}

final class PercentageDiscount extends Discount {
  final Decimal rate;

  const PercentageDiscount(this.rate);

  @override
  Money calculateAmount(Money baseAmount) => Money(baseAmount.amount * rate);
}

final class CouponDiscount extends Discount {
  final Money amount;
  final String name;

  const CouponDiscount(this.amount, {this.name = ''});

  @override
  Money calculateAmount(Money baseAmount) => amount;
}

class Offer {
  final String productName;
  final String storeName;
  final Money displayedPrice;
  final TaxMode taxMode;
  final Decimal taxRate;
  final Quantity quantity;
  final List<Discount> discounts;

  Offer({
    required this.productName,
    this.storeName = '',
    required this.displayedPrice,
    required this.taxMode,
    required this.taxRate,
    required this.quantity,
    this.discounts = const [],
  }) {
    if (taxRate < Decimal.zero) {
      throw ArgumentError.value(taxRate, 'taxRate', 'must be non-negative');
    }
    if (quantity.value <= Decimal.zero) {
      throw ArgumentError.value(
        quantity.value,
        'quantity',
        'must be greater than zero',
      );
    }
  }
}
