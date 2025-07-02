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

# テスト実行
log_step "テストを実行中..."
echo ""

"$TEST_EXECUTABLE"
TEST_RESULT=$?

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
fi

exit $TEST_RESULT