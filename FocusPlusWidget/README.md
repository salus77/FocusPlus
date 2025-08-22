# FocusPlus Widget

FocusPlusアプリ用のiOSウィジェットです。ホーム画面やロック画面に配置して、ポモドーロタイマーの進捗と状態を確認できます。

## 機能

### 3つのサイズに対応
- **小サイズ**: 完了数とタイマー状態を表示
- **中サイズ**: 完了数とタイマー状態を左右に分けて表示
- **大サイズ**: 詳細な情報（完了数、タイマー状態、日時）を表示

### 表示される情報
- 今日完了したポモドーロ数
- タイマーの実行状態（実行中/停止中）
- 残り時間（実行中の場合）
- 現在の日時

## セットアップ手順

### 1. Xcodeプロジェクトに追加
1. XcodeでFocusPlusプロジェクトを開く
2. File → New → Target を選択
3. iOS → Widget Extension を選択
4. Product Name: `FocusPlusWidget` を入力
5. Language: `Swift` を選択
6. Include Configuration Intent: チェックを外す
7. Finish をクリック

### 2. App Groupsの設定
1. プロジェクトファイルを選択
2. メインアプリのターゲットを選択
3. Signing & Capabilities タブを開く
4. + Capability をクリック
5. App Groups を追加
6. `group.com.delmar.FocusPlus` を追加

### 3. ウィジェットターゲットの設定
1. ウィジェットターゲットを選択
2. Signing & Capabilities タブを開く
3. + Capability をクリック
4. App Groups を追加
5. `group.com.delmar.FocusPlus` を追加

### 4. Bundle Identifierの確認
- メインアプリ: `com.delmar.FocusPlus`
- ウィジェット: `com.delmar.FocusPlus.FocusPlusWidget`

## 使用方法

### ウィジェットの追加
1. ホーム画面で長押し
2. 左上の「+」ボタンをタップ
3. FocusPlusウィジェットを検索
4. 希望のサイズを選択
5. ウィジェットを追加

### ウィジェットの更新
ウィジェットは以下のタイミングで自動更新されます：
- タイマーの開始/停止/一時停止
- ポモドーロセッションの完了
- 5分間隔での定期更新

## 技術仕様

### 使用フレームワーク
- WidgetKit
- SwiftUI

### データ共有
- App Groupsを使用したUserDefaults
- メインアプリとウィジェット間でのデータ同期

### 更新頻度
- タイマー実行中: 1秒間隔
- 通常時: 5分間隔

## トラブルシューティング

### ウィジェットが表示されない
1. App Groupsの設定を確認
2. Bundle Identifierの設定を確認
3. プロジェクトをクリーンビルド

### データが更新されない
1. メインアプリでタイマーを操作
2. ウィジェットを長押しして「ウィジェットを更新」を選択

## 開発者向け情報

### ファイル構成
```
FocusPlusWidget/
├── FocusPlusWidget.swift      # メインウィジェットコード
├── Info.plist                 # ウィジェット設定
├── FocusPlusWidget.entitlements # App Groups設定
└── Assets.xcassets/           # アセット
```

### カスタマイズ
ウィジェットのデザインや表示内容を変更する場合は、`FocusPlusWidget.swift`内の各ビュー構造体を編集してください。
