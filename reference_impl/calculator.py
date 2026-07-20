"""
reference_impl/calculator.py

Kotlin計算エンジンの参照実装。
Pythonのdecimalモジュールを使用して、Kotlinと同じ計算ロジックを実装する。
テストケースの期待値生成と検証に使用される。

関連ファイル:
- reference_impl/generate_test_cases.py
- src/commonMain/kotlin/com/pricecompare/pricing/PriceCalculator.kt
- src/commonMain/kotlin/com/pricecompare/comparison/ComparisonEngine.kt
"""

from decimal import Decimal, ROUND_HALF_UP, getcontext

# 精度設定
getcontext().prec = 50

# 丸め関数
def round_money(value: Decimal) -> Decimal:
    """金額の丸め（小数点以下を切り上げ）"""
    return value.quantize(Decimal("1"), rounding=ROUND_HALF_UP)

def round_unit_price(value: Decimal) -> Decimal:
    """単位価格の丸め（小数点以下6桁 HALF_UP）"""
    return value.quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)

def base_price_excluding_tax(price: Decimal, tax_mode: str, tax_rate: Decimal) -> Decimal:
    """税抜価格を計算"""
    if tax_mode == "EXCLUDED":
        return price
    divisor = Decimal("1") + tax_rate
    return round_money(price / divisor)

def tax_amount(base_price: Decimal, tax_rate: Decimal) -> Decimal:
    """税額を計算"""
    return round_money(base_price * tax_rate)

def apply_item_discounts(amount: Decimal, discounts: list) -> tuple:
    """商品割引を適用"""
    current = amount
    total = Decimal("0")
    for d in discounts:
        if d["type"] == "percentage":
            disc = round_money(current * d["rate"])
            current -= disc
            total += disc
        elif d["type"] == "fixed":
            disc = min(d["amount"], current)
            current -= disc
            total += disc
    return current, total

def apply_coupons(amount: Decimal, coupons: list) -> tuple:
    """クーポンを適用"""
    current = amount
    total = Decimal("0")
    for c in coupons:
        disc = min(c["amount"], current)
        current -= disc
        total += disc
    return current, total

def is_shipping_free(subtotal: Decimal, threshold: Decimal | None) -> bool:
    """送料無料条件を判定"""
    if threshold is None:
        return False
    return subtotal >= threshold

def calculate(offer: dict, context: dict) -> dict:
    """価格計算のメインロジック"""
    warnings = []

    # 1. 税抜価格
    base_excl = base_price_excluding_tax(
        offer["displayed_price"],
        offer["tax_mode"],
        Decimal(str(offer["tax_rate"]))
    )

    # 2. 税計算
    tax = tax_amount(base_excl, Decimal(str(offer["tax_rate"])))
    price_incl = base_excl + tax

    # 3. 商品割引
    item_discounted, item_discount_total = apply_item_discounts(
        price_incl, offer.get("discounts", [])
    )

    # 4. クーポン
    coupon_discounted, coupon_total = apply_coupons(
        item_discounted, context.get("order_coupons", [])
    )

    # 5. 送料無料条件判定
    shipping = context.get("shipping_cost")
    threshold = context.get("free_shipping_threshold")
    if shipping is not None:
        if is_shipping_free(coupon_discounted, threshold):
            effective_shipping = Decimal("0")
        else:
            effective_shipping = Decimal(str(shipping))
    else:
        effective_shipping = None
        warnings.append("送料が未入力のため、確定比較ではありません")

    # 6. 支払額
    used_points_value = Decimal(str(context.get("used_points", 0))) * Decimal(str(context.get("point_evaluation_rate", "1.0")))
    if effective_shipping is not None:
        payable_now = coupon_discounted + effective_shipping - used_points_value
    else:
        payable_now = None

    # 7. 獲得ポイント評価
    earned_points_value = Decimal(str(context.get("earned_points", 0))) * Decimal(str(context.get("point_evaluation_rate", "1.0")))

    # 8. 実質負担額
    effective_cost = payable_now - earned_points_value if payable_now is not None else None

    # 9. 単位価格
    quantity = offer["quantity"]
    base_unit_value = Decimal(str(quantity["value"]))
    if quantity["unit"] in ["kg"]:
        base_unit_value *= Decimal("1000")
    elif quantity["unit"] in ["L"]:
        base_unit_value *= Decimal("1000")

    if base_unit_value > 0:
        unit_price = round_unit_price((effective_cost if effective_cost is not None else coupon_discounted) * Decimal("100") / base_unit_value)
    else:
        unit_price = None

    return {
        "base_price_excluding_tax": str(round_money(base_excl)),
        "tax_amount": str(round_money(tax)),
        "price_including_tax": str(round_money(price_incl)),
        "total_item_discount": str(round_money(item_discount_total)),
        "total_coupon_discount": str(round_money(coupon_total)),
        "point_redemption": str(round_money(used_points_value)),
        "shipping_cost": str(effective_shipping) if effective_shipping is not None else None,
        "payable_now": str(payable_now) if payable_now is not None else None,
        "earned_points_value": str(round_money(earned_points_value)),
        "effective_cost": str(effective_cost) if effective_cost is not None else None,
        "unit_price": str(unit_price) if unit_price is not None else None,
        "warnings": warnings
    }

def compare(offer_a: dict, context_a: dict, offer_b: dict, context_b: dict) -> dict:
    """2商品比較"""
    breakdown_a = calculate(offer_a, context_a)
    breakdown_b = calculate(offer_b, context_b)

    warnings = list(set(breakdown_a["warnings"] + breakdown_b["warnings"]))

    # 単位互換性チェック
    unit_a = offer_a["quantity"]["unit"]
    unit_b = offer_b["quantity"]["unit"]
    base_units = {"g": "weight", "kg": "weight", "ml": "capacity", "L": "capacity", "個": "count", "枚": "count", "本": "count", "袋": "count"}
    if base_units.get(unit_a) != base_units.get(unit_b):
        return {
            "breakdown_a": breakdown_a,
            "breakdown_b": breakdown_b,
            "cheapest_by_payable": None,
            "cheapest_by_effective": None,
            "cheapest_by_unit_price": None,
            "payable_difference": None,
            "effective_difference": None,
            "unit_price_difference_ratio": None,
            "warnings": warnings,
            "incompatibility_reason": f"単位が異なります（{unit_a} vs {unit_b}）。直接比較できません。"
        }

    # 支払額比較
    cheapest_payable = None
    if breakdown_a["payable_now"] is not None and breakdown_b["payable_now"] is not None:
        pa, pb = Decimal(breakdown_a["payable_now"]), Decimal(breakdown_b["payable_now"])
        if pa < pb: cheapest_payable = 0
        elif pa > pb: cheapest_payable = 1

    # 実質負担額比較
    cheapest_effective = None
    if breakdown_a["effective_cost"] is not None and breakdown_b["effective_cost"] is not None:
        ea, eb = Decimal(breakdown_a["effective_cost"]), Decimal(breakdown_b["effective_cost"])
        if ea < eb: cheapest_effective = 0
        elif ea > eb: cheapest_effective = 1

    # 単位価格比較
    cheapest_unit = None
    if breakdown_a["unit_price"] is not None and breakdown_b["unit_price"] is not None:
        ua, ub = Decimal(breakdown_a["unit_price"]), Decimal(breakdown_b["unit_price"])
        if ua < ub: cheapest_unit = 0
        elif ua > ub: cheapest_unit = 1

    # 差額
    payable_diff = None
    if breakdown_a["payable_now"] is not None and breakdown_b["payable_now"] is not None:
        payable_diff = str(abs(Decimal(breakdown_a["payable_now"]) - Decimal(breakdown_b["payable_now"])))

    effective_diff = None
    if breakdown_a["effective_cost"] is not None and breakdown_b["effective_cost"] is not None:
        effective_diff = str(abs(Decimal(breakdown_a["effective_cost"]) - Decimal(breakdown_b["effective_cost"])))

    # 差率
    unit_ratio = None
    if breakdown_a["unit_price"] is not None and breakdown_b["unit_price"] is not None:
        ua, ub = Decimal(breakdown_a["unit_price"]), Decimal(breakdown_b["unit_price"])
        if ub != 0:
            unit_ratio = str(round_unit_price((ua - ub) / ub))

    return {
        "breakdown_a": breakdown_a,
        "breakdown_b": breakdown_b,
        "cheapest_by_payable": cheapest_payable,
        "cheapest_by_effective": cheapest_effective,
        "cheapest_by_unit_price": cheapest_unit,
        "payable_difference": payable_diff,
        "effective_difference": effective_diff,
        "unit_price_difference_ratio": unit_ratio,
        "warnings": warnings,
        "incompatibility_reason": None
    }
