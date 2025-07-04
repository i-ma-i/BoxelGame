#!/bin/bash

# BoxelGame - LinuxとWindowsの開発環境セットアップスクリプト

set -e  # エラーで停止

# 共通関数読み込み
source "$(dirname "$0")/common.sh"

setup_linux() {
    log_info "Linuxの開発環境をセットアップします"
    echo ""

    log_info "アプリ開発用パッケージをインストール中..."
    sudo apt install -y \
        git \
        cmake \
        pkg-config \
        build-essential \
        ninja-build \
        gdb

    log_info "ウィンドウシステム用パッケージをインストール中..."
    sudo apt install -y \
        libx11-dev \
        libxrandr-dev \
        libxinerama-dev \
        libxcursor-dev \
        libxi-dev \
        libwayland-dev \
        libxkbcommon-dev \
        wayland-protocols \
        libdecor-0-dev

    log_info "グラフィックスAPI用パッケージをインストール中..."
    sudo apt install -y \
        libegl1-mesa-dev
    # sudo apt install -y \
    #     libgl1-mesa-dev \
    #     libegl1-mesa-dev \
    #     libglu1-mesa-dev
}

setup_windows() {
    log_info "Windowsの開発環境をセットアップします"
    echo ""
    log_info "Windows開発環境確認開始..."

    if ! command -v cmake &> /dev/null; then
        log_warn "✗ CMakeをインストールしてください"
        log_info "  https://cmake.org/download/"
    else
        log_info "✓ CMakeが見つかりました"
    fi
}

echo "=========================================="
echo "BoxelGame 開発環境セットアップ"
echo "=========================================="

# プラットフォーム検出
PLATFORM=$(detect_platform)

if [[ "$PLATFORM" != "linux" && "$PLATFORM" != "windows" ]]; then
    log_error "サポートされていないプラットフォーム: $PLATFORM"
    log_error "サポートプラットフォーム: Linux, Windows (Git Bash)"
    exit 1
fi

if [[ "$PLATFORM" == "linux" ]]; then
    setup_linux
elif [[ "$PLATFORM" == "windows" ]]; then
    setup_windows
fi

echo ""
log_info "=========================================="
log_info "セットアップ完了!"
log_info "次のコマンドでビルドを開始できます:"
echo ""
echo "  cd $(dirname $(realpath $0))/.."
echo "  ./scripts/build.sh"
echo ""
log_info "=========================================="
