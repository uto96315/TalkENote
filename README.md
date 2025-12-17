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

## 📦 データストア構成（録音）

- Firebase Storage  
  - `recordings/{userId}/{recordingId}.m4a`
- Cloud Firestore  
  - Collection: `recordings`  
    - Doc: `{recordingId}`  
      - `userId`: string  
      - `storagePath`: string (Storage上のフルパス)  
      - `durationSec`: number  
      - `uploadStatus`: "pending" | "uploaded" | "failed"  
      - `createdAt`: Timestamp (serverTimestamp)  
      - `title`: string (optional)  
      - `memo`: string (optional)  
      - `newWords`: string[] (optional)

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
## MVPには入らないけど実装したい機能
- [ ] 通知機能
- [ ] コントロールセンターに設置
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
