#!/bin/bash

# BoxelGame - テスト実行スクリプト
# このスクリプトはテストを実行し、結果を表示します

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
echo "BoxelGame テスト実行"
echo "=========================================="

# ビルドタイプ設定（デフォルト: Debug）
BUILD_TYPE=${1:-Debug}
PRESET=""

# プラットフォーム検出
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_info "プラットフォーム: Linux"
    if [ "$BUILD_TYPE" = "Release" ]; then
        PRESET="linux-release"
        TEST_EXECUTABLE="build/$PRESET/tests/BoxelGameTests"
    else
        PRESET="linux-debug"
        TEST_EXECUTABLE="build/$PRESET/tests/BoxelGameTests"
    fi
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    log_info "プラットフォーム: Windows"
    if [ "$BUILD_TYPE" = "Release" ]; then
        PRESET="windows-release"
    else
        PRESET="windows-debug"
    fi
    TEST_EXECUTABLE="build/$PRESET/tests/$BUILD_TYPE/BoxelGameTests.exe"
else
    log_error "サポートされていないプラットフォーム: $OSTYPE"
    exit 1
fi

log_info "ビルドタイプ: $BUILD_TYPE"
log_info "テスト実行ファイル: $TEST_EXECUTABLE"

# テスト実行ファイル存在確認
if [ ! -f "$TEST_EXECUTABLE" ]; then
    log_error "テスト実行ファイルが見つかりません: $TEST_EXECUTABLE"
    log_info "先にビルドを実行してください:"
    echo "  ./scripts/build.sh $BUILD_TYPE"
    exit 1
fi

# Linux環境でのグラフィックス確認
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_step "グラフィックス環境を確認中..."
    
    if [ -n "$DISPLAY" ]; then
        log_info "X11セッション検出: $DISPLAY"
    elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        log_info "Waylandセッション検出"
    else
        log_warn "グラフィックス環境が検出されません"
        log_warn "統合テストが失敗する可能性があります（論理テストは実行されます）"
    fi
    
    # 仮想ディスプレイ使用オプション
    USE_XVFB=${2:-"auto"}
    
    if [ "$USE_XVFB" = "xvfb" ] || ([ "$USE_XVFB" = "auto" ] && [ -z "$DISPLAY" ] && [ "$XDG_SESSION_TYPE" != "wayland" ]); then
        if command -v xvfb-run &> /dev/null; then
            log_info "仮想ディスプレイ（Xvfb）を使用してテストを実行します"
            XVFB_PREFIX="xvfb-run -a"
        else
            log_warn "xvfb-run が見つかりません。統合テストが失敗する可能性があります"
            XVFB_PREFIX=""
        fi
    else
        XVFB_PREFIX=""
    fi
fi

# テスト実行
log_step "テストを実行中..."
echo ""

if [[ "$OSTYPE" == "linux-gnu"* ]] && [ -n "$XVFB_PREFIX" ]; then
    $XVFB_PREFIX "$TEST_EXECUTABLE"
    TEST_RESULT=$?
else
    "$TEST_EXECUTABLE"
    TEST_RESULT=$?
fi

echo ""

# 結果表示
if [ $TEST_RESULT -eq 0 ]; then
    log_info "=========================================="
    log_info "✓ すべてのテストが成功しました！"
    log_info "=========================================="
else
    log_error "=========================================="
    log_error "✗ テストが失敗しました（終了コード: $TEST_RESULT）"
    log_error "=========================================="
    
    # エラーメッセージ
    echo ""
    log_info "トラブルシューティング:"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "1. 依存関係確認:"
        echo "   ./scripts/setup-ubuntu.sh"
        echo ""
        echo "2. EGLライブラリ確認:"
        echo "   sudo apt install libegl1-mesa-dev"
        echo ""
        echo "3. 仮想ディスプレイでテスト:"
        echo "   ./scripts/test.sh Debug xvfb"
    else
        echo "1. 依存関係確認:"
        echo "   ./scripts/setup-windows.ps1"
        echo ""
        echo "2. Developer Command Prompt で実行しているか確認"
    fi
fi

exit $TEST_RESULT