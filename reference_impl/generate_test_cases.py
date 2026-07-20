"""
reference_impl/generate_test_cases.py

Python参照実装のcalcuator.pyを使用して、
Kotlinテスト用のtest_cases.jsonを生成する。

関連ファイル:
- reference_impl/calculator.py
- src/commonTest/resources/test_cases.json
"""

import json
import os
from calculator import calculate, compare

def make_offer(name, price, tax_mode, tax_rate, qty_value, qty_unit, discounts=None, store=""):
    return {
        "product_name": name,
        "store_name": store,
        "displayed_price": price,
        "tax_mode": tax_mode,
        "tax_rate": tax_rate,
        "quantity": {"value": qty_value, "unit": qty_unit},
        "discounts": discounts or []
    }

def make_context(shipping=None, threshold=None, coupons=None, used_points=0, earned_points=0, point_rate="1.0"):
    return {
        "shipping_cost": shipping,
        "free_shipping_threshold": threshold,
        "order_coupons": coupons or [],
        "used_points": used_points,
        "earned_points": earned_points,
        "point_evaluation_rate": point_rate
    }

def tc(name, offer_a, ctx_a, offer_b, ctx_b):
    result = compare(offer_a, ctx_a, offer_b, ctx_b)
    return {
        "name": name,
        "offer_a": offer_a,
        "context_a": ctx_a,
        "offer_b": offer_b,
        "context_b": ctx_b,
        "expected": result
    }

def generate():
    cases = []

    # 1. 基本: 税込2商品比較
    cases.append(tc("tax_included_basic",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(),
        make_offer("商品B", "1200", "INCLUDED", "0.1", "600", "g"),
        make_context()
    ))

    # 2. 税抜入力
    cases.append(tc("tax_excluded",
        make_offer("商品A", "900", "EXCLUDED", "0.1", "500", "g"),
        make_context(),
        make_offer("商品B", "1000", "EXCLUDED", "0.1", "500", "g"),
        make_context()
    ))

    # 3. 税率混在 (8% vs 10%)
    cases.append(tc("tax_rate_mix",
        make_offer("軽減税率商品", "1000", "INCLUDED", "0.08", "500", "g"),
        make_context(),
        make_offer("標準税率商品", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context()
    ))

    # 4. 10%引き + 100円引き
    cases.append(tc("percentage_then_fixed",
        make_offer("商品A", "2000", "INCLUDED", "0.1", "1", "個",
                   [{"type": "percentage", "rate": "0.1"}]),
        make_context(),
        make_offer("商品B", "2000", "INCLUDED", "0.1", "1", "個",
                   [{"type": "fixed", "amount": "100"}]),
        make_context()
    ))

    # 5. 複数クーポン
    cases.append(tc("multiple_coupons",
        make_offer("商品A", "3000", "INCLUDED", "0.1", "1", "個"),
        make_context(coupons=[{"amount": 500, "name": "クーポンA"}, {"amount": 200, "name": "クーポンB"}]),
        make_offer("商品B", "3000", "INCLUDED", "0.1", "1", "個"),
        make_context(coupons=[{"amount": 600, "name": "クーポンC"}])
    ))

    # 6. 送料無料条件（3000円以上）
    cases.append(tc("free_shipping_threshold",
        make_offer("商品A", "2500", "INCLUDED", "0.1", "1", "個"),
        make_context(shipping=500, threshold=3000),
        make_offer("商品B", "2800", "INCLUDED", "0.1", "1", "個"),
        make_context(shipping=500, threshold=3000)
    ))

    # 7. ポイント還元（100pt）
    cases.append(tc("point_redemption",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=100),
        make_offer("商品B", "1050", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=50)
    ))

    # 8. 容量違い（500ml vs 1L）
    cases.append(tc("capacity_difference",
        make_offer("商品A", "500", "INCLUDED", "0.1", "500", "ml"),
        make_context(),
        make_offer("商品B", "900", "INCLUDED", "0.1", "1", "L"),
        make_context()
    ))

    # 9. 送料未入力
    cases.append(tc("shipping_not_entered",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "1", "個"),
        make_context(),
        make_offer("商品B", "1000", "INCLUDED", "0.1", "1", "個"),
        make_context(shipping=None)
    ))

    # 10. ポイント評価率0.8
    cases.append(tc("point_evaluation_rate_low",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=100, point_rate="0.8"),
        make_offer("商品B", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=0, point_rate="0.8")
    ))

    # 11. マイナス実質負担（高額ポイント還元）
    cases.append(tc("negative_effective_cost",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=1500),
        make_offer("商品B", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=0)
    ))

    # 12. 完全一致（差額0）
    cases.append(tc("exact_match",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(),
        make_offer("商品B", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context()
    ))

    # 13. 税込/税抜混在比較
    cases.append(tc("tax_included_excluded_mix",
        make_offer("税込商品", "1100", "INCLUDED", "0.1", "500", "g"),
        make_context(),
        make_offer("税抜商品", "1000", "EXCLUDED", "0.1", "500", "g"),
        make_context()
    ))

    # 14. 送料500円込み比較
    cases.append(tc("shipping_included",
        make_offer("商品A", "800", "INCLUDED", "0.1", "500", "g"),
        make_context(shipping=500),
        make_offer("商品B", "1200", "INCLUDED", "0.1", "500", "g"),
        make_context(shipping=0)
    ))

    # 15. 割引なし
    cases.append(tc("no_discounts",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g", []),
        make_context(),
        make_offer("商品B", "1000", "INCLUDED", "0.1", "500", "g", []),
        make_context()
    ))

    # 16. 同一商品
    cases.append(tc("identical_items",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(),
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context()
    ))

    # 17. 大口金額（10万円）
    cases.append(tc("large_amount",
        make_offer("高額商品A", "100000", "INCLUDED", "0.1", "5", "kg"),
        make_context(),
        make_offer("高額商品B", "95000", "INCLUDED", "0.1", "5", "kg"),
        make_context()
    ))

    # 18. 小口金額（10円）
    cases.append(tc("small_amount",
        make_offer("廉価商品A", "10", "INCLUDED", "0.1", "100", "g"),
        make_context(),
        make_offer("廉価商品B", "15", "INCLUDED", "0.1", "100", "g"),
        make_context()
    ))

    # 19. 単位: kg vs g
    cases.append(tc("unit_kg_vs_g",
        make_offer("商品A", "500", "INCLUDED", "0.1", "0.5", "kg"),
        make_context(),
        make_offer("商品B", "600", "INCLUDED", "0.1", "500", "g"),
        make_context()
    ))

    # 20. 単位: L vs ml
    cases.append(tc("unit_L_vs_ml",
        make_offer("商品A", "500", "INCLUDED", "0.1", "1", "L"),
        make_context(),
        make_offer("商品B", "600", "INCLUDED", "0.1", "1000", "ml"),
        make_context()
    ))

    # 21. 単位: 個数
    cases.append(tc("unit_count",
        make_offer("商品A", "100", "INCLUDED", "0.1", "10", "個"),
        make_context(),
        make_offer("商品B", "180", "INCLUDED", "0.1", "20", "個"),
        make_context()
    ))

    # 22. 異次元不可（g vs ml）
    cases.append(tc("incompatible_dimensions",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(),
        make_offer("商品B", "1000", "INCLUDED", "0.1", "500", "ml"),
        make_context()
    ))

    # 23. 送料未入力 + ポイントあり
    cases.append(tc("shipping_not_entered_with_points",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=100),
        make_offer("商品B", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=100)
    ))

    # 24. クーポン + 送料無料
    cases.append(tc("coupon_plus_free_shipping",
        make_offer("商品A", "3500", "INCLUDED", "0.1", "1", "個"),
        make_context(shipping=500, threshold=3000, coupons=[{"amount": 500, "name": "割引"}]),
        make_offer("商品B", "3500", "INCLUDED", "0.1", "1", "個"),
        make_context(shipping=500, threshold=3000)
    ))

    # 25. 税抜 + 送料 + ポイント
    cases.append(tc("tax_excluded_shipping_points",
        make_offer("商品A", "1000", "EXCLUDED", "0.1", "500", "g"),
        make_context(shipping=500, earned_points=100),
        make_offer("商品B", "1000", "EXCLUDED", "0.1", "600", "g"),
        make_context(shipping=500, earned_points=50)
    ))

    # 26. 割引率100%（無料商品）
    cases.append(tc("full_discount",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g",
                   [{"type": "percentage", "rate": "1.0"}]),
        make_context(),
        make_offer("商品B", "100", "INCLUDED", "0.1", "500", "g"),
        make_context()
    ))

    # 27. 端数処理確認（1円未満）
    cases.append(tc("rounding_edge",
        make_offer("商品A", "111", "INCLUDED", "0.08", "3", "個"),
        make_context(),
        make_offer("商品B", "111", "INCLUDED", "0.08", "3", "個"),
        make_context()
    ))

    # 28. ポイント評価率0（ポイント無効）
    cases.append(tc("point_rate_zero",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=100, point_rate="0"),
        make_offer("商品B", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=100, point_rate="0")
    ))

    # 29. ポイント評価率2.0（高評価）
    cases.append(tc("point_rate_high",
        make_offer("商品A", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=100, point_rate="2.0"),
        make_offer("商品B", "1000", "INCLUDED", "0.1", "500", "g"),
        make_context(earned_points=50, point_rate="2.0")
    ))

    # 30. 送料無料条件ギリギリ
    cases.append(tc("free_shipping_boundary",
        make_offer("商品A", "2999", "INCLUDED", "0.1", "1", "個"),
        make_context(shipping=500, threshold=3000),
        make_offer("商品B", "3000", "INCLUDED", "0.1", "1", "個"),
        make_context(shipping=500, threshold=3000)
    ))

    # 31. 複数割引適用
    cases.append(tc("multiple_discounts",
        make_offer("商品A", "5000", "INCLUDED", "0.1", "1", "kg",
                   [{"type": "percentage", "rate": "0.1"}, {"type": "fixed", "amount": "500"}]),
        make_context(),
        make_offer("商品B", "5000", "INCLUDED", "0.1", "1", "kg",
                   [{"type": "fixed", "amount": "500"}, {"type": "percentage", "rate": "0.1"}]),
        make_context()
    ))

    # 32. 使用ポイント
    cases.append(tc("used_points",
        make_offer("商品A", "2000", "INCLUDED", "0.1", "500", "g"),
        make_context(used_points=500, point_rate="1.0"),
        make_offer("商品B", "1800", "INCLUDED", "0.1", "500", "g"),
        make_context(used_points=0)
    ))

    # 33. クーポン + ポイント
    cases.append(tc("coupon_and_points",
        make_offer("商品A", "3000", "INCLUDED", "0.1", "1", "個"),
        make_context(coupons=[{"amount": 300, "name": "クーポン"}], used_points=200),
        make_offer("商品B", "2500", "INCLUDED", "0.1", "1", "個"),
        make_context(coupons=[{"amount": 300, "name": "クーポン"}], used_points=0)
    ))

    # 34. 税抜 + 割引
    cases.append(tc("tax_excluded_with_discount",
        make_offer("商品A", "1000", "EXCLUDED", "0.1", "500", "g",
                   [{"type": "percentage", "rate": "0.1"}]),
        make_context(),
        make_offer("商品B", "1000", "EXCLUDED", "0.1", "500", "g",
                   [{"type": "fixed", "amount": "100"}]),
        make_context()
    ))

    # 35. 送料無料 + ポイント
    cases.append(tc("free_shipping_with_points",
        make_offer("商品A", "5000", "INCLUDED", "0.1", "1", "個"),
        make_context(shipping=500, threshold=3000, earned_points=500),
        make_offer("商品B", "5000", "INCLUDED", "0.1", "1", "個"),
        make_context(shipping=500, threshold=3000, earned_points=200)
    ))

    return cases

def main():
    cases = generate()

    # test_cases.json生成
    output_path = os.path.join(os.path.dirname(__file__), "..", "src", "commonTest", "resources", "test_cases.json")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(cases, f, ensure_ascii=False, indent=2)

    print(f"Generated {len(cases)} test cases to {output_path}")

    # 検証
    errors = 0
    for case in cases:
        result = compare(case["offer_a"], case["context_a"], case["offer_b"], case["context_b"])
        expected = case["expected"]
        if result != expected:
            print(f"FAIL: {case['name']}")
            errors += 1
        else:
            print(f"OK: {case['name']}")

    print(f"\n{errors} errors out of {len(cases)} cases")

if __name__ == "__main__":
    main()
