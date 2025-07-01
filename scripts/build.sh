#!/bin/bash

# BoxelGame - クロスプラットフォーム ビルドスクリプト
# このスクリプトはプラットフォームを自動検出してビルドを実行します

set -e  # エラーで停止

# 色付きログ出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

echo "=========================================="
echo "BoxelGame ビルドスクリプト"
echo "=========================================="

# ビルドタイプ設定（デフォルト: Debug）
BUILD_TYPE=${1:-Debug}
PRESET=""

# プラットフォーム検出
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_info "プラットフォーム: Linux"
    if [ "$BUILD_TYPE" = "Release" ]; then
        PRESET="linux-release"
    else
        PRESET="linux-debug"
    fi
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    log_info "プラットフォーム: Windows"
    if [ "$BUILD_TYPE" = "Release" ]; then
        PRESET="windows-release"
    else
        PRESET="windows-debug"
    fi
else
    log_error "サポートされていないプラットフォーム: $OSTYPE"
    exit 1
fi

log_info "ビルドタイプ: $BUILD_TYPE"
log_info "CMakeプリセット: $PRESET"

# 依存関係確認
log_step "依存関係を確認中..."

if ! command -v cmake &> /dev/null; then
    log_error "CMakeが見つかりません。先にセットアップスクリプトを実行してください。"
    exit 1
fi

if ! command -v ninja &> /dev/null && [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_error "Ninjaが見つかりません。先にセットアップスクリプトを実行してください。"
    exit 1
fi

log_info "CMake: $(cmake --version | head -1)"

# PKG_CONFIG環境変数設定（Linux）
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -z "$PKG_CONFIG_EXECUTABLE" ]; then
        export PKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config
        log_info "PKG_CONFIG_EXECUTABLE: $PKG_CONFIG_EXECUTABLE"
    fi
fi

# ビルドディレクトリクリーンアップ（オプション）
if [ "$2" = "--clean" ] || [ "$2" = "-c" ]; then
    log_step "ビルドディレクトリをクリーンアップ中..."
    rm -rf build
    log_info "クリーンアップ完了"
fi

# CMake設定
log_step "CMake設定を実行中..."
cmake --preset "$PRESET"

if [ $? -ne 0 ]; then
    log_error "CMake設定に失敗しました"
    exit 1
fi

log_info "CMake設定完了"

# ビルド実行
log_step "ビルドを実行中..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linuxでは--configオプションは不要（Ninjaジェネレータ）
    cmake --build "build/$PRESET"
else
    # WindowsではMulti-config generator（Visual Studio）を使用
    cmake --build "build/$PRESET" --config "$BUILD_TYPE"
fi

if [ $? -ne 0 ]; then
    log_error "ビルドに失敗しました"
    exit 1
fi

log_info "ビルド完了"

# 実行ファイル確認
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    EXECUTABLE="build/$PRESET/bin/BoxelGame"
    TEST_EXECUTABLE="build/$PRESET/tests/BoxelGameTests"
else
    EXECUTABLE="build/$PRESET/bin/$BUILD_TYPE/BoxelGame.exe"
    TEST_EXECUTABLE="build/$PRESET/tests/$BUILD_TYPE/BoxelGameTests.exe"
fi

if [ -f "$EXECUTABLE" ]; then
    log_info "実行ファイル: $EXECUTABLE"
else
    log_warn "実行ファイルが見つかりません: $EXECUTABLE"
fi

if [ -f "$TEST_EXECUTABLE" ]; then
    log_info "テスト実行ファイル: $TEST_EXECUTABLE"
else
    log_warn "テスト実行ファイルが見つかりません: $TEST_EXECUTABLE"
fi

echo ""
echo "=========================================="
log_info "ビルド完了!"
echo ""
echo "次のコマンドでテストを実行できます:"
echo "  ./scripts/test.sh"
echo ""
echo "実行ファイルを直接実行:"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "  ./$EXECUTABLE"
else
    echo "  $EXECUTABLE"
fi
echo "=========================================="