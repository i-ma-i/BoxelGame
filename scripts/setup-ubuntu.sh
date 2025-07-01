#!/bin/bash

# BoxelGame - Ubuntu/Debian セットアップスクリプト
# このスクリプトは必要な依存関係をインストールします

set -e  # エラーで停止

# 共通関数読み込み
source "$(dirname "$0")/common.sh"

echo "=========================================="
echo "BoxelGame Ubuntu/Debian セットアップ"
echo "=========================================="

# OS確認
if ! command -v apt &> /dev/null; then
    log_error "このスクリプトはUbuntu/Debian系OSでのみ動作します"
    exit 1
fi

log_info "OS: $(lsb_release -d | cut -f2)"

# 管理者権限確認
if [ "$EUID" -eq 0 ]; then
    log_warn "rootユーザーで実行しています。一般ユーザーでの実行を推奨します。"
fi

# WSL環境でのnvidia-smi検出関数
check_nvidia_smi() {
    # 標準パスでの確認
    if command -v nvidia-smi &> /dev/null; then
        return 0
    fi
    
    # WSL特有のパスでの確認
    if [ -f "/usr/lib/wsl/lib/nvidia-smi" ]; then
        log_info "WSL環境のnvidia-smiを検出: /usr/lib/wsl/lib/nvidia-smi"
        # WSLパスをPATHに追加
        export PATH="/usr/lib/wsl/lib:$PATH"
        return 0
    fi
    
    return 1
}

# WSL環境パスの設定
setup_wsl_paths() {
    log_info "WSL環境パスを設定中..."
    
    BASHRC_FILE="$HOME/.bashrc"
    WSL_PATH_SETTINGS="
# WSL NVIDIA Paths (BoxelGame)
export PATH=\"/usr/lib/wsl/lib:\$PATH\""
    
    # 既存の設定をチェック
    if grep -q "WSL NVIDIA Paths (BoxelGame)" "$BASHRC_FILE" 2>/dev/null; then
        log_info "✓ WSL環境パスは既に設定済みです"
    else
        echo "$WSL_PATH_SETTINGS" >> "$BASHRC_FILE"
        log_info "✓ WSL環境パスを ~/.bashrc に追加しました"
    fi
    
    # 現在のセッションに適用
    export PATH="/usr/lib/wsl/lib:$PATH"
}

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

# OpenGL/EGL関連パッケージ
log_info "OpenGL/EGL関連パッケージをインストール中..."
sudo apt install -y \
    libegl1-mesa-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libgles2-mesa-dev

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
    clang-format-15 \
    clang-tidy-15 \
    xvfb \
    pciutils \
    mesa-utils

# WSL環境パスのセットアップ（NVIDIA検出前に実行）
setup_wsl_paths

# NVIDIA GPU関連パッケージ（WSL2対応）※オプション
log_info "NVIDIA GPU関連パッケージをインストール中（オプション）..."
if check_nvidia_smi; then
    log_info "nvidia-smi が検出されました - NVIDIA GPU対応環境"
    
    # Vulkan関連
    sudo apt install -y \
        vulkan-tools \
        libnvidia-gl-525 \
        nvidia-cuda-toolkit || {
        log_warn "一部のNVIDIA GPU関連パッケージのインストールに失敗しました（正常です）"
    }
    
    # WSL GPU パススルー用の追加設定
    log_info "WSL GPU パススルー設定を確認中..."
    if [ -e "/dev/dxg" ]; then
        log_info "✓ WSL GPU デバイス (/dev/dxg) が検出されました"
        
        # 必要な環境変数設定の提案
        log_info "NVIDIA GPU を使用するための環境変数設定:"
        echo "  export __NV_PRIME_RENDER_OFFLOAD=1"
        echo "  export __GLX_VENDOR_LIBRARY_NAME=nvidia"
        echo "  export DRI_PRIME=1"
        echo ""
        echo "これらの設定を ~/.bashrc や ~/.profile に追加することを推奨します"
    else
        log_warn "WSL GPU デバイス (/dev/dxg) が見つかりません"
        log_warn "WSL2でGPU パススルーを有効にする必要があります"
    fi
else
    log_warn "nvidia-smi が見つかりません - NVIDIA GPU非対応環境"
    log_info "統合GPU (Intel/AMD) 環境での開発となります"
fi







# バージョン確認
log_info "インストール済みバージョン確認:"
show_cmake_version
echo "  GCC: $(gcc --version | head -1)"
echo "  Ninja: $(ninja --version)"

# EGLライブラリ確認
log_info "EGLライブラリ確認:"
if pkg-config --exists egl; then
    echo "  EGL: $(pkg-config --modversion egl)"
    log_info "✓ EGLライブラリが正常に検出されました"
else
    log_warn "⚠ EGLライブラリが検出されません"
fi

# OpenGLライブラリ確認
if pkg-config --exists gl; then
    echo "  OpenGL: $(pkg-config --modversion gl)"
    log_info "✓ OpenGLライブラリが正常に検出されました"
else
    log_warn "⚠ OpenGLライブラリが検出されません"
fi

# Wayland環境確認
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    log_info "現在のセッション: Wayland"
else
    log_warn "現在のセッション: $XDG_SESSION_TYPE (X11の可能性)"
    log_warn "Waylandでテストする場合は、Waylandセッションでログインしてください"
fi



echo ""
log_info "=========================================="
log_info "セットアップ完了!"
log_info "次のコマンドでビルドを開始できます:"
echo ""
echo "  cd $(dirname $(realpath $0))/.."
echo "  ./scripts/build.sh"
echo ""
if check_nvidia_smi; then
    log_info "NVIDIA GPU テストコマンド:"
    echo "  ./build/default/tests/BoxelGameTests --test-case=\"*システムGPU検出テスト*\""
fi
echo ""
log_info "=========================================="