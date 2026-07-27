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

  const ProductInput({
    this.displayedPrice = '',
    this.taxMode = TaxMode.taxIncluded,
    this.taxRatePercent = '10',
    this.quantity = '',
    this.unit = ComparisonUnit.gram,
  });

  ProductInput copyWith({
    String? displayedPrice,
    TaxMode? taxMode,
    String? taxRatePercent,
    String? quantity,
    ComparisonUnit? unit,
  }) =>
      ProductInput(
        displayedPrice: displayedPrice ?? this.displayedPrice,
        taxMode: taxMode ?? this.taxMode,
        taxRatePercent: taxRatePercent ?? this.taxRatePercent,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
      );
}

class PriceCompareState {
  final ProductInput inputA;
  final ProductInput inputB;
  final String shippingCost;
  final ComparisonResult? result;
  final String? errorMessage;

  const PriceCompareState({
    this.inputA = const ProductInput(),
    this.inputB = const ProductInput(),
    this.shippingCost = '',
    this.result,
    this.errorMessage,
  });
}

class PriceCompareNotifier extends StateNotifier<PriceCompareState> {
  PriceCompareNotifier() : super(const PriceCompareState());

  void updateInputA(ProductInput input) {
    state = PriceCompareState(
      inputA: input,
      inputB: state.inputB,
      shippingCost: state.shippingCost,
      result: state.result,
    );
  }

  void updateInputB(ProductInput input) {
    state = PriceCompareState(
      inputA: state.inputA,
      inputB: input,
      shippingCost: state.shippingCost,
      result: state.result,
    );
  }

  void updateShippingCost(String shippingCost) {
    state = PriceCompareState(
      inputA: state.inputA,
      inputB: state.inputB,
      shippingCost: shippingCost,
      result: state.result,
    );
  }

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
      state = PriceCompareState(
        inputA: state.inputA,
        inputB: state.inputB,
        shippingCost: state.shippingCost,
        result: result,
      );
      return true;
    } on FormatException catch (error) {
      _setError(error.message);
    } on ArgumentError catch (error) {
      _setError(error.message?.toString() ?? error.toString());
    }
    return false;
  }

  void clearResult() {
    state = PriceCompareState(
      inputA: state.inputA,
      inputB: state.inputB,
      shippingCost: state.shippingCost,
    );
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
    );
  }

  PurchaseContext _toPurchaseContext() {
    final shipping = state.shippingCost.trim();
    return shipping.isEmpty
        ? PurchaseContext()
        : PurchaseContext(shippingCost: Money(Decimal(shipping)));
  }

  void _setError(String message) {
    state = PriceCompareState(
      inputA: state.inputA,
      inputB: state.inputB,
      shippingCost: state.shippingCost,
      errorMessage: message,
    );
  }
}

final priceCompareProvider =
    StateNotifierProvider<PriceCompareNotifier, PriceCompareState>(
  (ref) => PriceCompareNotifier(),
);
