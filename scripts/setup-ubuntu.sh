#!/bin/bash

set -e

echo "Ubuntu開発環境セットアップ開始..."

sudo sudo apt update
sudo sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    git

sudo sudo apt install -y \
#    libegl1-mesa-dev \
#    libgl1-mesa-dev \
    libx11-dev \
    libxrandr-dev \
    libxcursor-dev \
    libxi-dev \
    libwayland-dev \
    libxkbcommon-dev \
    wayland-protocols

sudo sudo apt install -y xvfb

echo "Ubuntu開発環境セットアップ完了!"
echo "次のコマンドでビルドできます:"
echo "  ./scripts/build.sh"