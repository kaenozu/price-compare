# Price Compare

スーパードラッグストア・ネット通販の商品価格比較Androidアプリ。

## 概要

- 税込/税抜、割引、クーポン、ポイント還元、送料、容量差を含めて比較
- 代表値: 支払額(payableNow)、実質負担額(effectiveCost)、単位価格(unitCost)
- Phase 2では2商品を入力して比較できる最小Compose UIを提供

## 技術スタック

- Kotlin Multiplatform（計算エンジン）
- Kotlin + Jetpack Compose / Material3（Android UI）
- ViewModel + StateFlow
- Kotlinx Serialization JSON
- BigDecimal（任意精度10進数）

## プロジェクト構成

```
app/                         - Android Composeアプリ
src/
  commonMain/kotlin/com/pricecompare/
    model/                   - データモデル (Money, Quantity, Offer, etc.)
    pricing/                 - 価格計算ロジック
    comparison/              - 比較エンジン
    util/                    - ユーティリティ
  androidMain/               - Android固有の実装 (Decimal)
  jvmMain/                   - JVM固有の実装 (Decimal)
  commonTest/                - 計算エンジンのテストコード
reference_impl/              - Python参照実装
```

## ビルド・テスト

```bash
./gradlew jvmTest
./gradlew :app:testDebugUnitTest
./gradlew :app:assembleDebug
```

## Phase 2 UI

Android Studioでプロジェクトを開き、`app` 実行構成を選択して起動します。

1. 商品A・商品Bの表示価格、税込/税抜、税率、数量、単位を入力
2. 「比較する」を押す
3. 支払額、実質負担額、100基準単位あたりの価格、最安商品を確認

## Python参照実装

```bash
cd reference_impl
python generate_test_cases.py
python calculator.py ../src/commonTest/resources/test_cases.json
```

## 仕様

[SPEC.md](SPEC.md) を参照。
