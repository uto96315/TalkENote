# TalkENote（トーク・イー・ノート）

**TalkENote は、あなたの「日常会話」をそのまま英語ノートに変えるアプリです。**  
録音 → 文字起こし → 自動英訳 → 単語・フレーズ抽出までをワンタップで。  
勉強というより “メモ感覚” で続けられる新しい英語学習体験を目指しています。

---

## ✨ MVPで実装する機能
- 🎤 **録音（シーン単位・常時録音ではない）**
- 📝 **日本語の文字起こし（自動）**
- 🌐 **日本語 → 英語の翻訳**
- 📚 **単語・フレーズの抽出**
- 📒 **会話ログ表示（日本語と英語を並べて表示）**
- ⏱ **無料版：1セッション5分の録音制限**

---

## 🔧 技術スタック（予定）
- Flutter
- Firebase
- 文字起こしAPI（Whisper / 各種STT）
- 翻訳API（DeepL / Google Translate）

---

## アーキテクチャ
```
lib/
├── app/                     // MaterialApp、Route、AppLifecycle などアプリの根幹
│   ├── routes.dart
│   └── app.dart
├── constants/               // 定数・固定値・アプリ設定
│   ├── enums/               // enum（RecState, LangType など）
│   ├── strings/             // 固定文言（i18n前提なら最小限でOK）
│   ├── config/              // APIキー・設定値・AppConfig
│   ├── colors.dart          // ← AppColors を置く場所
│   └── mock/                // 開発用モックデータ
├── data/
│   ├── model/               // DTO（APIレスポンス、Firebaseドキュメントなど）
│   ├── repository/          // Repository層（データ取得、Firebase, API）
│   └── datasource/          // ローカル・リモートのDataSource
├── domain/
│   ├── entity/              // 純粋なビジネスEntity（会話、単語など）
│   ├── usecase/             // ビジネスロジック（録音開始、翻訳実行など）
│   └── converter/           // Model → Entity の変換
├── service/                 // 外部サービス（録音、STT、翻訳、ログ）
│   ├── audio_service.dart
│   ├── stt_service.dart
│   ├── translation_service.dart
│   └── logger_service.dart
├── ui/
│   ├── home/                // ホーム画面（録音ボタンなど）
│   ├── result/              // 翻訳結果表示画面
│   ├── log/                 // 会話ログ一覧
│   ├── vocab/               // 単語帳
│   └── common/              // 共通UI（Button, Card, Dialog）
├── provider/                // Riverpodの状態用（ViewModel含む）
│   ├── home_provider.dart
│   ├── record_provider.dart
│   ├── stt_provider.dart
│   ├── translation_provider.dart
│   └── vocab_provider.dart
├── util/                    // 汎用ユーティリティ（formatter, validator）
├── extension/               // 拡張関数
├── theme/                   // ThemeData、TextStyle、Padding等
│   ├── app_theme.dart
│   ├── typography.dart
│   └── spacing.dart
└── firebase_options.dart
```

---

## 🎯 プロジェクト目標
**12/14に MVP をリリースする！**

---

## 📘 コンセプト
英語学習は “勉強” じゃなくていい。  
TalkENote は、あなたが普段しゃべっている会話をそのまま英語ノートにしてくれます。

学ぶのは「教材の英語」ではなく、  
**“あなた自身の言葉を英語にすること”**。

---

## 🗺️ 今後の短期ロードマップ
### 📅 Day 0（今日）— デザイン & プロジェクト骨格づくり
- [x] アプリ名選定（TalkENote）
- [ ] テーマカラー決定
- [ ] ロゴ案作成
- [ ] アプリアイコン作成
- [ ] スプラッシュ画面素材作成
- [x] MVVM仕様でディレクトリ構成作成
- [ ] Firebaseセットアップ（Auth / Firestore / Storage 必要なら）
- [ ] ざっくり画面遷移図（3画面）

👉 今日の目的は デザインと骨組みを終わらせる
→ 明日以降の実装スピードが段違いに上がる。

### 📅 Day 1 — 録音 → STT → 翻訳の“心臓部”を完成させる日
- [ ] 必要ライブラリのインストール
  - [ ] record（録音）
  - [ ] Firebase関連
  - [ ] build_runner / freezed
  - [ ] 翻訳系API（DeepL or OpenAI）
- [ ] ホーム画面の最低限UI作成（録音 / 停止 / 変換ボタン）
- [ ] 録音機能の実装
- [ ] 録音の動作テスト
- [ ] STT（文字起こし）APIの接続
- [ ] 翻訳API接続
- [ ] 一連の処理を直列化（録音 → STT → 翻訳）
- [ ] 録音→テキスト→英語 の動作確認

👉 この日が一番重要。MVPの80%がここで完成する。

### 📅 Day 2 — 画面構築 & 結果表示
- [ ] 結果画面作成（日本語 / 英語の並列表示）
- [ ] ローディングインジケーター実装
- [ ] エラーハンドリング追加
- [ ] 会話ログ保存処理（まずはローカルでOK）
- [ ] 会話ログ一覧画面作成
- [ ] UIを仮でまとめ、最低限使える形にする

👉 見える形になる日。アプリらしくなってくる。

### 📅 Day 3 — 単語抽出 & 学習要素（簡易版）
- [ ] 英文から単語抽出（スペース区切り）
- [ ] ストップワード除外処理
- [ ] 単語の出現回数をカウント
- [ ] 単語帳画面（シンプルな一覧）
- [ ] 「覚えたい」チェック機能
- [ ] UIの最小整形

👉 MVPなので“簡単でOK”。後からいくらでも伸ばせる。

### 📅 Day 4 — デザイン反映 & 微調整
- [ ] アプリアイコン適用（flutter_launcher_icons）
- [ ] スプラッシュ画面適用（flutter_native_splash）
- [ ] テーマカラー反映
- [ ] UI調整（余白、色、フォントなど）
- [ ] ボタン反応改善
- [ ] エラー時の処理改善
- [ ] 全体通しテスト

👉 見た目がよくなり、アプリとして完成度が急上昇。

### 📅 Day 5 — 実機テスト & バグ修正
- [ ] iOS実機テスト（録音→翻訳→保存）
- [ ] Android実機テスト
- [ ] ログ保存の動作確認
- [ ] 単語抽出の動作確認
- [ ] 不具合修正
- [ ] STT・翻訳の精度確認

👉 ここで 本物として動くか を検証する。

### 📅 Day 6 — リリース準備
- [ ] README更新（機能一覧・使い方）
- [ ] GitHubにタグ付け（v0.1）
- [ ] iOS TestFlight ビルド作成
- [ ] Android APK作成
- [ ] 内部テスト招待準備

👉 MVP完成！！！🔥

### 📅 Day 7 — 予備日（余裕あれば）
- [ ] 友人・彼女などにテスト配布
- [ ] フィードバック収集
- [ ] 軽微な修正




---
## MVPには入らないけど実装したい機能
- [ ] 通知機能
- [ ] レビュー依頼
- [ ] 課金機能
- [ ] テスト書いてみたい
- [ ] 匿名認証
- [ ] 広告
- [ ] 多言語対応
- [ ] コントロールセンターに設置

## よく使うコマンド
 - どのアカウントでgitにログインしているか 
```
gh auth status
```

## 📄 ライセンス
MIT License
