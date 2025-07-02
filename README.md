# BoxelGame

![CI/CD Pipeline](https://github.com/username/BoxelGame/workflows/CI%2FCD%20Pipeline/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Language](https://img.shields.io/badge/language-C%2B%2B23-blue.svg)
![OpenGL](https://img.shields.io/badge/OpenGL-4.6-green.svg)

**BoxelGame** は C++23 と Modern OpenGL を使用した Minecraft 風のボクセルサンドボックスゲームエンジンです。RAII 原則、ECS アーキテクチャ、マルチプラットフォーム対応を重視した実装を行っています。

## 特徴

- **Modern C++23**: 最新の C++ 標準を使用
- **OpenGL 4.6 Core Profile**: 高性能なレンダリング
- **Wayland サポート**: Linux の現代的なウィンドウシステム対応
- **クロスプラットフォーム**: Windows と Linux 対応
- **CI/CD パイプライン**: GitHub Actions による自動ビルド・テスト
- **開発ツール**: 最適化されたビルドスクリプト、統合テスト

## 将来の機能

- ボクセルベースの地形生成
- チャンク式ワールド管理（256×256×256）
- リアルタイムの地形編集
- マルチプレイヤー対応（将来実装予定）

## システム要件

### 最小要件
- **OS**: Windows 10/11 (x64) または Ubuntu 20.04+ (x64)
- **GPU**: OpenGL 4.6 対応 GPU
- **メモリ**: 4 GB RAM
- **ストレージ**: 100 MB

### 推奨要件
- **GPU**: GTX 760 / RX 460 以上
- **CPU**: Intel i5-4690 / AMD Ryzen 5 1600 以上
- **メモリ**: 8 GB RAM

## セットアップ・ビルド

### 1. リポジトリの取得

```bash
git clone https://github.com/username/BoxelGame.git
cd BoxelGame
```

### 2. 環境のセットアップ

#### 開発環境セットアップ:
```bash
./scripts/setup-dev-env.sh
```

### 3. ビルドの実行

```bash
# Debug ビルド（デフォルト）
./scripts/build.sh

# Release ビルド
./scripts/build.sh Release

# クリーンビルド
./scripts/build.sh Debug --clean
```

### 4. テストの実行

```bash
# Debug テスト
./scripts/test.sh Debug

# Release テスト
./scripts/test.sh Release
```

## CMake プリセット

```bash
# Linux Debug ビルド
cmake --preset linux-debug

# Linux Release
cmake --preset linux-release

# Windows Debug
cmake --preset windows-debug

# Windows Release
cmake --preset windows-release
```

## プロジェクト構造

```
BoxelGame/
├── src/         # ソースコード
├── include/     # ヘッダーファイル
├── tests/       # テストコード
├── scripts/     # 開発用スクリプト
├── docs/        # ドキュメント
├── assets/      # ゲームアセット
├── deps/        # 外部依存関係
├── cmake/       # CMake 設定
└── build/       # ビルド出力
```

## 開発

### CI/CD
- **GitHub Actions**: 自動ビルド・テスト・リリース
- **プラットフォーム**: Ubuntu (GCC) & Windows (MSVC)
- **ビルドタイプ**: Debug & Release

### コーディング規約
- **C++23 標準**: Modern C++ の機能を積極的に使用
- **RAII 原則**: リソース管理の徹底
- **テスト駆動開発**: 論理テストと統合テストの分離

### リリース

リリースビルドの作成:
```bash
./scripts/build.sh Release
```

実行ファイルの場所:
- **Linux**: `build/linux-release/bin/BoxelGame`
- **Windows**: `build/windows-release/bin/Release/BoxelGame.exe`

---
