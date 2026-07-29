from __future__ import annotations

import json
from decimal import Decimal
from pathlib import Path

from calculator import calculate


VECTORS = (
    Path(__file__).resolve().parents[1]
    / "test_vectors"
    / "price_breakdown_cases.json"
)


def test_shared_vectors_match_python_reference() -> None:
    cases = json.loads(VECTORS.read_text(encoding="utf-8"))

    for case in cases:
        offer = {
            "product_name": case["name"],
            "store_name": "",
            "displayed_price": Decimal(case["displayedPrice"]),
            "tax_mode": (
                "INCLUDED" if case["taxMode"] == "included" else "EXCLUDED"
            ),
            "tax_rate": Decimal(case["taxRate"]),
            "quantity": {
                "value": Decimal(case["quantity"]),
                "unit": case["unit"],
            },
            "discounts": [],
        }
        context = {
            "shipping_cost": Decimal(case["shippingCost"]),
            "free_shipping_threshold": None,
            "order_coupons": [],
            "used_points": case["usedPoints"],
            "earned_points": case["earnedPoints"],
            "point_evaluation_rate": Decimal(case["pointEvaluationRate"]),
        }

        result = calculate(offer, context)

        assert Decimal(result["payable_now"]) == Decimal(
            case["expectedPayableNow"]
        ), case["name"]
        assert Decimal(result["effective_cost"]) == Decimal(
            case["expectedEffectiveCost"]
        ), case["name"]
        assert Decimal(result["unit_price"]) == Decimal(
            case["expectedUnitPrice"]
        ), case["name"]
