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

class PurchaseContextInput {
  final String shippingCost;
  final String couponAmount;
  final String usedPoints;
  final String earnedPoints;

  const PurchaseContextInput({
    this.shippingCost = '',
    this.couponAmount = '',
    this.usedPoints = '',
    this.earnedPoints = '',
  });

  bool get hasAny =>
      [shippingCost, couponAmount, usedPoints, earnedPoints]
          .any((value) => value.isNotEmpty);

  PurchaseContextInput copyWith({
    String? shippingCost,
    String? couponAmount,
    String? usedPoints,
    String? earnedPoints,
  }) =>
      PurchaseContextInput(
        shippingCost: shippingCost ?? this.shippingCost,
        couponAmount: couponAmount ?? this.couponAmount,
        usedPoints: usedPoints ?? this.usedPoints,
        earnedPoints: earnedPoints ?? this.earnedPoints,
      );
}

class PriceCompareState {
  final ProductInput inputA;
  final ProductInput inputB;
  final PurchaseContextInput contextA;
  final PurchaseContextInput contextB;
  final ComparisonResult? result;
  final String? errorMessage;

  const PriceCompareState({
    this.inputA = const ProductInput(),
    this.inputB = const ProductInput(),
    this.contextA = const PurchaseContextInput(),
    this.contextB = const PurchaseContextInput(),
    this.result,
    this.errorMessage,
  });

  // Compatibility getters for callers written before purchase conditions became
  // product-specific. Legacy update methods below continue to update both sides.
  String get shippingCost => contextA.shippingCost;
  String get couponAmount => contextA.couponAmount;
  String get usedPoints => contextA.usedPoints;
  String get earnedPoints => contextA.earnedPoints;
}

class PriceCompareNotifier extends StateNotifier<PriceCompareState> {
  PriceCompareNotifier() : super(const PriceCompareState());

  void _updateState({
    ProductInput? inputA,
    ProductInput? inputB,
    PurchaseContextInput? contextA,
    PurchaseContextInput? contextB,
    ComparisonResult? result,
  }) {
    state = PriceCompareState(
      inputA: inputA ?? state.inputA,
      inputB: inputB ?? state.inputB,
      contextA: contextA ?? state.contextA,
      contextB: contextB ?? state.contextB,
      result: result,
    );
  }

  void updateInputA(ProductInput input) => _updateState(inputA: input);

  void updateInputB(ProductInput input) => _updateState(inputB: input);

  void updateContextA(PurchaseContextInput input) =>
      _updateState(contextA: input);

  void updateContextB(PurchaseContextInput input) =>
      _updateState(contextB: input);

  // Backward-compatible shared updates. New UI code must use updateContextA/B.
  void updateShippingCost(String value) => _updateBothContexts(
        (input) => input.copyWith(shippingCost: value),
      );

  void updateCouponAmount(String value) => _updateBothContexts(
        (input) => input.copyWith(couponAmount: value),
      );

  void updateUsedPoints(String value) => _updateBothContexts(
        (input) => input.copyWith(usedPoints: value),
      );

  void updateEarnedPoints(String value) => _updateBothContexts(
        (input) => input.copyWith(earnedPoints: value),
      );

  void _updateBothContexts(
    PurchaseContextInput Function(PurchaseContextInput input) update,
  ) {
    _updateState(
      contextA: update(state.contextA),
      contextB: update(state.contextB),
    );
  }

  bool compare() {
    try {
      final offerA = _toOffer('商品A', state.inputA);
      final offerB = _toOffer('商品B', state.inputB);
      final result = ComparisonEngine.compare(
        offerA: offerA,
        contextA: _toPurchaseContext(state.contextA),
        offerB: offerB,
        contextB: _toPurchaseContext(state.contextB),
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
    if (amount < Decimal.zero) {
      throw ArgumentError(
        input.discountIsPercent
            ? '割引率は0〜100%で入力してください'
            : '割引額は0以上で入力してください',
      );
    }
    if (amount.isZero) return const [];
    if (input.discountIsPercent) {
      if (amount > Decimal('100')) {
        throw ArgumentError('割引率は0〜100%で入力してください');
      }
      return [PercentageDiscount(amount / Decimal('100'))];
    }
    return [FixedAmountDiscount(Money(amount))];
  }

  Offer _toOffer(String name, ProductInput input) {
    final price = Decimal(input.displayedPrice.trim());
    final quantity = Decimal(input.quantity.trim());
    final taxRatePercent = Decimal(input.taxRatePercent.trim());

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

  PurchaseContext _toPurchaseContext(PurchaseContextInput input) {
    final shippingCost = _parseOptionalMoney(input.shippingCost, '送料');
    final couponAmount = _parseOptionalMoney(input.couponAmount, 'クーポン');
    final coupons = couponAmount == null
        ? <CouponDiscount>[]
        : [CouponDiscount(couponAmount, name: 'クーポン')];

    return PurchaseContext(
      shippingCost: shippingCost,
      orderCoupons: coupons,
      usedPoints: _parsePoints(input.usedPoints, '使用ポイント'),
      earnedPoints: _parsePoints(input.earnedPoints, '獲得ポイント'),
    );
  }

  Money? _parseOptionalMoney(String rawValue, String label) {
    final value = rawValue.trim();
    if (value.isEmpty) return null;

    final amount = Decimal(value);
    if (amount < Decimal.zero) {
      throw ArgumentError('$labelは0以上で入力してください');
    }
    return Money(amount);
  }

  int _parsePoints(String rawValue, String label) {
    final value = rawValue.trim();
    if (value.isEmpty) return 0;

    final points = int.tryParse(value);
    if (points == null || points < 0) {
      throw ArgumentError('$labelは0以上の整数で入力してください');
    }
    return points;
  }

  void _setError(String message) {
    state = PriceCompareState(
      inputA: state.inputA,
      inputB: state.inputB,
      contextA: state.contextA,
      contextB: state.contextB,
      errorMessage: message,
    );
  }
}

final priceCompareProvider =
    StateNotifierProvider<PriceCompareNotifier, PriceCompareState>(
  (ref) => PriceCompareNotifier(),
);
