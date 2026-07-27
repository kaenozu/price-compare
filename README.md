# アイミツモリ（Price Compare）

スーパー、ドラッグストア、ネット通販の商品を、税込・税抜、割引、クーポン、ポイント、送料、容量差まで含めて比較するAndroidアプリです。

## 現在地

- Kotlin Multiplatform製の価格計算コアを実装済み
- `flutter_app/` にFlutter + Riverpodの最小UIとDart版計算エンジンを実装済み
- Flutterの静的解析、単体テスト、Providerテスト、UIスモークテストをGitHub Actionsで実行
- Kotlin計算エンジンの`jvmTest`もGitHub Actionsで実行
- Androidプラットフォーム雛形（`flutter_app/android/`）は未コミットのため、APK実機確認は次の最優先タスク

## 採用路線

Flutter実装をプライマリクライアントとし、`main`を統合先とします。

- `feature/phase1-calculation-engine`: Kotlin計算エンジンの起点。履歴は`main`へ継承済み
- `feature/phase2-flutter`: Flutter初期実装。現在の`main`はこのブランチより先行
- `feature/phase2-minimal-ui`: Jetpack Composeの技術検証ブランチ。参照用として保持し、並行開発は行わない

新規作業は`main`から短命なfeature/agentブランチを作成し、PRで統合します。詳細は[ADR 0001](docs/adr/0001-flutter-primary-client.md)を参照してください。

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

Flutter SDKはCIと同じ`3.44.0`を基準にします。

## Kotlin側の検証

現在は`gradle/wrapper/gradle-wrapper.jar`が欠けているため、CIではGradle 8.7を固定して実行します。

```bash
gradle jvmTest
```

Wrapperを復旧した後は、環境差を抑えるため`./gradlew jvmTest`を標準コマンドに戻します。

計算仕様を変更する場合は、Kotlin・Dart・Python参照実装の期待値を同じ変更単位で確認します。次の品質タスクは、共通JSONテストベクトルをDart側でも読み込むパリティテストの追加です。

## 開発優先順位

1. `main`をGitHubの既定ブランチに設定し、必須CIチェックを有効化する
2. Gradle Wrapper JARをGradle 8.7で再生成・コミットし、CIを`./gradlew`へ戻す
3. Androidプラットフォーム雛形を生成し、applicationId、アプリ名、minSdk/targetSdk、署名除外を確定する
4. Android Debug APKをCIでビルドし、入力→比較結果までの実機スモークテストを行う
5. Kotlin/Dart間の共通テストベクトルによるパリティテストを追加する
6. 商品名、店舗名、送料、割引、クーポン、ポイント入力をUIへ段階的に追加する
7. ローカル保存、比較履歴、AdMob/Billingは計算・入力UXが安定してから導入する

詳細仕様は[SPEC.md](SPEC.md)を参照してください。
