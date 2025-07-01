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

# パッケージリストの更新
log_info "パッケージリストを更新中..."
sudo apt update

# 必須パッケージのインストール
log_info "必須パッケージをインストール中..."
sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    git

# OpenGL関連パッケージ
log_info "OpenGL関連パッケージをインストール中..."
sudo apt install -y \
    libegl1-mesa-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev

# Wayland関連パッケージ
log_info "Wayland関連パッケージをインストール中..."
sudo apt install -y \
    libwayland-dev \
    libxkbcommon-dev \
    wayland-protocols

# X11関連パッケージ（X11環境での動作も保証）
log_info "X11関連パッケージをインストール中..."
sudo apt install -y \
    libx11-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxcursor-dev \
    libxi-dev \
    libxxf86vm-dev

# 開発ツール（オプション）
log_info "開発ツールをインストール中..."
sudo apt install -y \
    xvfb


echo ""
log_info "=========================================="
log_info "セットアップ完了!"
log_info "次のコマンドでビルドを開始できます:"
echo ""
echo "  cd $(dirname $(realpath $0))/.."
echo "  ./scripts/build.sh"
echo ""
log_info "=========================================="