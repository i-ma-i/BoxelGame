#!/bin/bash

# BoxelGame - クロスプラットフォーム ビルドスクリプト
# このスクリプトはプラットフォームを自動検出してビルドを実行します

set -e  # エラーで停止

# 共通関数読み込み
source "$(dirname "$0")/common.sh"

# プロジェクトルートに移動
move_to_project_root

echo "=========================================="
echo "BoxelGame ビルドスクリプト"
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

log_info "プラットフォーム: $PLATFORM"
log_info "ビルドタイプ: $BUILD_TYPE"
log_info "CMakeプリセット: $PRESET"

# 依存関係確認
log_step "依存関係を確認中..."
if ! check_dependencies "$PLATFORM"; then
    exit 1
fi

show_cmake_version

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
if [ "$PLATFORM" = "linux" ]; then
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
EXECUTABLE=$(get_executable_path "$PLATFORM" "$PRESET" "$BUILD_TYPE" "BoxelGame" "false")
TEST_EXECUTABLE=$(get_executable_path "$PLATFORM" "$PRESET" "$BUILD_TYPE" "BoxelGameTests" "true")

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
if [ "$PLATFORM" = "linux" ]; then
    echo "  ./$EXECUTABLE"
else
    echo "  $EXECUTABLE"
fi
echo "=========================================="