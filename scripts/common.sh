#!/bin/bash

# BoxelGame - 共通関数ライブラリ
# このライブラリは他のスクリプトから利用される共通機能を提供します

# 色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
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

# プラットフォーム検出関数
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# プリセット名生成関数
get_preset_name() {
    local platform="$1"
    local build_type="$2"
    
    if [ "$platform" = "linux" ]; then
        if [ "$build_type" = "Release" ]; then
            echo "linux-release"
        else
            echo "linux-debug"
        fi
    elif [ "$platform" = "windows" ]; then
        if [ "$build_type" = "Release" ]; then
            echo "windows-release"
        else
            echo "windows-debug"
        fi
    else
        log_error "サポートされていないプラットフォーム: $platform"
        return 1
    fi
}

# 実行ファイルパス生成関数
get_executable_path() {
    local platform="$1"
    local preset="$2"
    local build_type="$3"
    local executable_name="$4"
    local is_test="$5"
    
    if [ "$platform" = "linux" ]; then
        if [ "$is_test" = "true" ]; then
            echo "build/$preset/tests/$executable_name"
        else
            echo "build/$preset/bin/$executable_name"
        fi
    elif [ "$platform" = "windows" ]; then
        if [ "$is_test" = "true" ]; then
            echo "build/$preset/tests/$build_type/$executable_name.exe"
        else
            echo "build/$preset/bin/$build_type/$executable_name.exe"
        fi
    fi
}

# 依存関係確認関数
check_dependencies() {
    local platform="$1"
    
    # CMake確認
    if ! command -v cmake &> /dev/null; then
        log_error "CMakeが見つかりません。先にセットアップスクリプトを実行してください。"
        return 1
    fi
    
    # Linux特有の依存関係確認
    if [ "$platform" = "linux" ]; then
        if ! command -v ninja &> /dev/null; then
            log_error "Ninjaが見つかりません。先にセットアップスクリプトを実行してください。"
            return 1
        fi
        
        # PKG_CONFIG環境変数設定
        if [ -z "$PKG_CONFIG_EXECUTABLE" ]; then
            export PKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config
            log_info "PKG_CONFIG_EXECUTABLE: $PKG_CONFIG_EXECUTABLE"
        fi
    fi
    
    return 0
}

# プロジェクトルートに移動する関数
move_to_project_root() {
    cd "$(dirname "$0")/.."
}

# CMakeバージョン表示関数
show_cmake_version() {
    log_info "CMake: $(cmake --version | head -1)"
}