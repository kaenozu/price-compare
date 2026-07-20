# Price Compare

スーパードラッグストア・ネット通販の商品価格比較Androidアプリ。

## 概要

- 税込/税抜、割引、クーポン、ポイント還元、送料、容量差を含めて比較
- 代表値: 支払額(payableNow)、実質負担額(effectiveCost)、単位価格(unitCost)

## 技術スタック

- Kotlin Multiplatform (JVM)
- Kotlinx Serialization JSON
- BigDecimal (任意精度10進数)

## プロジェクト構成

```
src/
  commonMain/kotlin/com/pricecompare/
    model/          - データモデル (Money, Quantity, Offer, etc.)
    pricing/        - 価格計算ロジック
    comparison/     - 比較エンジン
    util/           - ユーティリティ
  jvmMain/          - JVM固有の実装 (Decimal)
  commonTest/       - テストコード
reference_impl/     - Python参照実装
```

## ビルド・テスト

```bash
./gradlew jvmTest
```

## Python参照実装

```bash
cd reference_impl
python generate_test_cases.py
python calculator.py ../src/commonTest/resources/test_cases.json
```

## 仕様

[SPEC.md](SPEC.md) を参照。
