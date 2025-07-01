#!/bin/bash

# BoxelGame - テスト実行スクリプト
# このスクリプトはテストを実行し、結果を表示します

set -e  # エラーで停止

# 共通関数読み込み
source "$(dirname "$0")/common.sh"

# プロジェクトルートに移動
move_to_project_root

echo "=========================================="
echo "BoxelGame テスト実行"
echo "=========================================="

# ビルドタイプ設定（デフォルト: Debug）
BUILD_TYPE=${1:-Debug}

# プラットフォーム検出とプリセット設定
PLATFORM=$(detect_platform)
if [ "$PLATFORM" = "unknown" ]; then
    log_error "サポートされていないプラットフォーム: $OSTYPE"
    exit 1
fi

PRESET=$(get_preset_name "$PLATFORM" "$BUILD_TYPE")
if [ $? -ne 0 ]; then
    exit 1
fi

TEST_EXECUTABLE=$(get_executable_path "$PLATFORM" "$PRESET" "$BUILD_TYPE" "BoxelGameTests" "true")

log_info "プラットフォーム: $PLATFORM"
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
if [ "$PLATFORM" = "linux" ]; then
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

if [ "$PLATFORM" = "linux" ] && [ -n "$XVFB_PREFIX" ]; then
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
    if [ "$PLATFORM" = "linux" ]; then
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