# ADR 0001: Flutterをプライマリクライアントとする

- Status: Accepted
- Date: 2026-07-27

## Context

価格比較アプリには、Kotlin Multiplatformの計算エンジン、Flutter + RiverpodのUI実装、Jetpack Composeの試作実装が存在する。

現在の`main`はFlutter実装を取り込み、生成物の除外、静的解析、単体テスト、Providerテスト、UIスモークテストまで整備済みである。一方、`feature/phase2-minimal-ui`はPhase 1から分岐した独立試作であり、`main`とは相互に未統合の変更を持つ。

## Decision

- `main`のFlutter実装をプライマリクライアントとする。
- `feature/phase2-minimal-ui`はComposeの技術検証・参照実装として保持し、新機能を並行実装しない。
- Kotlin Multiplatform版の計算エンジンとPython参照実装は、価格計算仕様の検証用オラクルとして維持する。
- Flutter/Dart版エンジンとの仕様差分は、共通JSONテストベクトルを利用するパリティテストで検出する。
- 新規開発ブランチは`main`から作成し、PRで統合する。

## Rationale

1. 既に`main`へFlutter向け品質ゲートとUIテストが積み上がっており、Composeへ切り替えると再統合コストが発生する。
2. FlutterはAndroid MVPを短期間で進めつつ、将来WebやiOSで検証する余地を残せる。
3. 開発言語の二重化による計算仕様のドリフトはリスクだが、共有テストベクトルとCIで管理できる。
4. ComposeはAndroid専用UIとして合理的だが、現時点で本線へ切り替えるだけの固有要件や性能上の必要性は確認されていない。

## Consequences

- FlutterのAndroidプラットフォーム雛形、Debug APKビルド、実機受入を優先する。
- KotlinとDartの計算エンジンを手作業で別々に変更してはならない。仕様変更時は参照ケースと双方のテストを同じPRで更新する。
- Compose実装の有用なUXやテストケースは、必要に応じてFlutter側へ移植する。
- Android固有API、性能、アクセシビリティ、配布要件がFlutterで満たせない証拠が得られた場合のみ、本決定を再検討する。
