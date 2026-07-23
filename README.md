# アイミツモリ（Price Compare）

スーパー、ドラッグストア、ネット通販の商品を、税込・税抜、割引、クーポン、ポイント、送料、容量差まで含めて比較するAndroidアプリです。

## 現在地

- Kotlin Multiplatform製の価格計算コアを実装済み
- `flutter_app/` にFlutter + Riverpodの最小UIとDart版計算エンジンを実装済み
- Flutterの単体テスト、Providerテスト、UIスモークテストをGitHub Actionsで実行
- Androidプラットフォーム雛形（`android/`）は未コミットのため、APK実機確認は次の最優先タスク

## 主な計算値

- `payableNow`: 会計時の支払額
- `effectiveCost`: ポイント還元などを反映した実質負担額
- `unitCost`: 容量差を正規化した単位価格

## 構成

```text
src/                    Kotlin Multiplatform版の価格計算コア
reference_impl/         Python参照実装
flutter_app/
  lib/engine/           Dart版の価格計算ロジック
  lib/providers/        Riverpod状態管理
  lib/ui/               商品入力・比較結果UI
  test/                 エンジン、Provider、UIテスト
```

## Flutter側の検証

```bash
cd flutter_app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
```

Flutter SDKはCIと同じ `3.44.0` を基準にします。

## Kotlin側の検証

```bash
./gradlew jvmTest
```

## 開発優先順位

1. Androidプラットフォーム雛形を生成し、applicationId、アプリ名、minSdk/targetSdk、署名除外を確定する
2. Android Debug APKをCIでビルドし、入力→比較結果までの実機スモークテストを行う
3. 商品名、店舗名、送料、割引、クーポン、ポイント入力をUIへ段階的に追加する
4. Hive等のローカル保存、比較履歴、AdMob/Billingは計算・入力UXが安定してから導入する

詳細仕様は [SPEC.md](SPEC.md) を参照してください。
