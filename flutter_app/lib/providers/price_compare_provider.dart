import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/comparison_engine.dart';
import '../engine/decimal.dart';
import '../engine/money.dart';
import '../engine/offer.dart';
import '../engine/purchase_context.dart';
import '../engine/quantity.dart';
import '../engine/tax_mode.dart';
import '../engine/unit.dart';

class ProductInput {
  final String displayedPrice;
  final TaxMode taxMode;
  final String taxRatePercent;
  final String quantity;
  final ComparisonUnit unit;
  final String discountValue;
  final bool discountIsPercent;

  const ProductInput({
    this.displayedPrice = '',
    this.taxMode = TaxMode.taxIncluded,
    this.taxRatePercent = '10',
    this.quantity = '',
    this.unit = ComparisonUnit.gram,
    this.discountValue = '',
    this.discountIsPercent = false,
  });

  ProductInput copyWith({
    String? displayedPrice,
    TaxMode? taxMode,
    String? taxRatePercent,
    String? quantity,
    ComparisonUnit? unit,
    String? discountValue,
    bool? discountIsPercent,
  }) =>
      ProductInput(
        displayedPrice: displayedPrice ?? this.displayedPrice,
        taxMode: taxMode ?? this.taxMode,
        taxRatePercent: taxRatePercent ?? this.taxRatePercent,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        discountValue: discountValue ?? this.discountValue,
        discountIsPercent: discountIsPercent ?? this.discountIsPercent,
      );
}

class PriceCompareState {
  final ProductInput inputA;
  final ProductInput inputB;
  final String shippingCost;
  final String couponAmount;
  final String usedPoints;
  final String earnedPoints;
  final ComparisonResult? result;
  final String? errorMessage;

  const PriceCompareState({
    this.inputA = const ProductInput(),
    this.inputB = const ProductInput(),
    this.shippingCost = '',
    this.couponAmount = '',
    this.usedPoints = '',
    this.earnedPoints = '',
    this.result,
    this.errorMessage,
  });
}

class PriceCompareNotifier extends StateNotifier<PriceCompareState> {
  PriceCompareNotifier() : super(const PriceCompareState());

  void _updateState({
    ProductInput? inputA,
    ProductInput? inputB,
    String? shippingCost,
    String? couponAmount,
    String? usedPoints,
    String? earnedPoints,
    ComparisonResult? result,
  }) {
    state = PriceCompareState(
      inputA: inputA ?? state.inputA,
      inputB: inputB ?? state.inputB,
      shippingCost: shippingCost ?? state.shippingCost,
      couponAmount: couponAmount ?? state.couponAmount,
      usedPoints: usedPoints ?? state.usedPoints,
      earnedPoints: earnedPoints ?? state.earnedPoints,
      result: result,
    );
  }

  void updateInputA(ProductInput input) => _updateState(inputA: input);

  void updateInputB(ProductInput input) => _updateState(inputB: input);

  void updateShippingCost(String v) => _updateState(shippingCost: v);

  void updateCouponAmount(String v) => _updateState(couponAmount: v);

  void updateUsedPoints(String v) => _updateState(usedPoints: v);

  void updateEarnedPoints(String v) => _updateState(earnedPoints: v);

  bool compare() {
    try {
      final offerA = _toOffer('商品A', state.inputA);
      final offerB = _toOffer('商品B', state.inputB);
      final context = _toPurchaseContext();
      final result = ComparisonEngine.compare(
        offerA: offerA,
        contextA: context,
        offerB: offerB,
        contextB: context,
      );
      _updateState(result: result);
      return true;
    } on FormatException catch (error) {
      _setError(error.message);
    } on ArgumentError catch (error) {
      _setError(error.message?.toString() ?? error.toString());
    }
    return false;
  }

  void clearResult() => _updateState(result: null);

  List<Discount> _parseDiscounts(ProductInput input) {
    final value = input.discountValue.trim();
    if (value.isEmpty) return const [];
    final amount = Decimal(value);
    if (amount <= Decimal.zero) return const [];
    if (input.discountIsPercent) {
      if (amount > Decimal('100')) {
        throw ArgumentError('割引率は100%以下で入力してください');
      }
      return [PercentageDiscount(amount / Decimal('100'))];
    }
    return [FixedAmountDiscount(Money(amount))];
  }

  Offer _toOffer(String name, ProductInput input) {
    final price = Decimal(input.displayedPrice);
    final quantity = Decimal(input.quantity);
    final taxRatePercent = Decimal(input.taxRatePercent);

    if (price < Decimal.zero) {
      throw ArgumentError('表示価格は0以上で入力してください');
    }
    if (quantity <= Decimal.zero) {
      throw ArgumentError('数量は0より大きい値を入力してください');
    }
    if (taxRatePercent < Decimal.zero || taxRatePercent > Decimal('100')) {
      throw ArgumentError('税率は0〜100%で入力してください');
    }

    return Offer(
      productName: name,
      displayedPrice: Money(price),
      taxMode: input.taxMode,
      taxRate: taxRatePercent / Decimal('100'),
      quantity: Quantity(value: quantity, unit: input.unit),
      discounts: _parseDiscounts(input),
    );
  }

  PurchaseContext _toPurchaseContext() {
    final shipping = state.shippingCost.trim();
    final coupon = state.couponAmount.trim();
    final used = state.usedPoints.trim();
    final earned = state.earnedPoints.trim();
    final shippingCost =
        shipping.isEmpty ? null : Money(Decimal(shipping));
    final coupons = coupon.isEmpty
        ? <CouponDiscount>[]
        : [CouponDiscount(Money(Decimal(coupon)), name: 'クーポン')];
    return PurchaseContext(
      shippingCost: shippingCost,
      orderCoupons: coupons,
      usedPoints: used.isEmpty ? 0 : int.parse(used),
      earnedPoints: earned.isEmpty ? 0 : int.parse(earned),
    );
  }

  void _setError(String message) {
    state = PriceCompareState(
      inputA: state.inputA,
      inputB: state.inputB,
      shippingCost: state.shippingCost,
      couponAmount: state.couponAmount,
      usedPoints: state.usedPoints,
      earnedPoints: state.earnedPoints,
      errorMessage: message,
    );
  }
}

final priceCompareProvider =
    StateNotifierProvider<PriceCompareNotifier, PriceCompareState>(
  (ref) => PriceCompareNotifier(),
);
