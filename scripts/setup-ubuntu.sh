#!/bin/bash

# BoxelGame - Ubuntu/Debian セットアップスクリプト
# このスクリプトは必要な依存関係をインストールします

set -e  # エラーで停止

# 共通関数読み込み
source "$(dirname "$0")/common.sh"

echo "=========================================="
echo "BoxelGame Ubuntu/Debian セットアップ"
echo "=========================================="

log_info "OS: $(lsb_release -d | cut -f2)"

log_info "パッケージリストを更新中..."
sudo apt update

log_info "アプリ開発用パッケージをインストール中..."
sudo apt install -y \
    git \
    cmake \
    pkg-config \
    build-essential \
    ninja-build

log_info "ウィンドウシステム用パッケージをインストール中..."
sudo apt install -y \
    libwayland-dev \
    libxkbcommon-dev \
    wayland-protocols

log_info "グラフィックスAPI用パッケージをインストール中..."
sudo apt install -y \
    libgl1-mesa-dev \
    libegl1-mesa-dev \
    libglu1-mesa-dev

# 開発ツール（オプション）
log_info "開発ツールをインストール中..."
sudo apt install -y \
    gdb

echo ""
log_info "=========================================="
log_info "セットアップ完了!"
log_info "次のコマンドでビルドを開始できます:"
echo ""
echo "  cd $(dirname $(realpath $0))/.."
echo "  ./scripts/build.sh"
echo ""
log_info "=========================================="