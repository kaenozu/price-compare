# Flutter app

`flutter_app/` はアイミツモリのFlutter UI実装です。

## 必須環境

- Flutter 3.44.0
- Dart 3.12系（Flutter同梱）

## 品質チェック

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
```

## 現在の制約

`android/` プラットフォーム雛形はまだコミットされていません。次の作業でFlutter標準テンプレートから生成し、applicationIdを `com.kaenozu.aimitsumori` として固定したうえで、Debug APKビルドとAndroid実機確認を追加します。
