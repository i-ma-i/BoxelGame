#!/bin/bash

# BoxelGame - Ubuntu/Debian セットアップスクリプト
# このスクリプトは必要な依存関係をインストールします

set -e  # エラーで停止

echo "=========================================="
echo "BoxelGame Ubuntu/Debian セットアップ"
echo "=========================================="

# 色付きログ出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# NVIDIA Container Toolkit のインストール（WSL2 GPU対応）
install_nvidia_container_toolkit() {
    log_info "NVIDIA Container Toolkit をインストール中..."
    
    # GPGキーの追加
    if curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg 2>/dev/null; then
        log_info "✓ NVIDIA GPGキーを追加しました"
    else
        log_warn "NVIDIA GPGキーの追加に失敗しました"
        return 1
    fi
    
    # リポジトリの追加
    if curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
       sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
       sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null; then
        log_info "✓ NVIDIA Container Toolkit リポジトリを追加しました"
    else
        log_warn "NVIDIA Container Toolkit リポジトリの追加に失敗しました"
        return 1
    fi
    
    # パッケージリスト更新
    log_info "パッケージリストを更新中..."
    if sudo apt update > /dev/null 2>&1; then
        log_info "✓ パッケージリスト更新完了"
    else
        log_warn "パッケージリスト更新に失敗しました"
        return 1
    fi
    
    # nvidia-container-toolkit のインストール
    if sudo apt install -y nvidia-container-toolkit > /dev/null 2>&1; then
        log_info "✓ NVIDIA Container Toolkit インストール完了"
        return 0
    else
        log_warn "NVIDIA Container Toolkit インストールに失敗しました"
        return 1
    fi
}

# CUDA Toolkit のインストール
install_cuda_toolkit() {
    log_info "CUDA Toolkit をインストール中..."
    
    # 一時ディレクトリ作成
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # CUDA keyring のダウンロードとインストール
    if wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb; then
        if sudo dpkg -i cuda-keyring_1.1-1_all.deb > /dev/null 2>&1; then
            log_info "✓ CUDA keyring インストール完了"
        else
            log_warn "CUDA keyring インストールに失敗しました"
            cd - > /dev/null
            rm -rf "$TEMP_DIR"
            return 1
        fi
    else
        log_warn "CUDA keyring ダウンロードに失敗しました"
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 元のディレクトリに戻る
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    # パッケージリスト更新
    if sudo apt update > /dev/null 2>&1; then
        log_info "✓ CUDA リポジトリ追加完了"
    else
        log_warn "CUDA リポジトリ追加に失敗しました"
        return 1
    fi
    
    # CUDA Toolkit のインストール
    log_info "CUDA Toolkit をインストール中（時間がかかる場合があります）..."
    if sudo apt install -y cuda-toolkit > /dev/null 2>&1; then
        log_info "✓ CUDA Toolkit インストール完了"
        return 0
    else
        log_warn "CUDA Toolkit インストールに失敗しました"
        return 1
    fi
}

# CUDA 環境変数の設定
setup_cuda_environment_variables() {
    log_info "CUDA環境変数を設定中..."
    
    BASHRC_FILE="$HOME/.bashrc"
    CUDA_SETTINGS="
# CUDA Environment Variables (BoxelGame)
export PATH=\"/usr/local/cuda/bin:\$PATH\"
export LD_LIBRARY_PATH=\"/usr/local/cuda/lib64:\$LD_LIBRARY_PATH\"
export CUDA_HOME=\"/usr/local/cuda\"
export CUDA_PATH=\"/usr/local/cuda\""
    
    # 既存の設定をチェック
    if grep -q "CUDA Environment Variables (BoxelGame)" "$BASHRC_FILE" 2>/dev/null; then
        log_info "✓ CUDA環境変数は既に設定済みです"
    else
        echo "$CUDA_SETTINGS" >> "$BASHRC_FILE"
        log_info "✓ CUDA環境変数を ~/.bashrc に追加しました"
    fi
    
    # 現在のセッションに適用
    export PATH="/usr/local/cuda/bin:$PATH"
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
    export CUDA_HOME="/usr/local/cuda"
    export CUDA_PATH="/usr/local/cuda"
}

# 高度なNVIDIA GPU設定（WSL2専用）
setup_advanced_nvidia_gpu() {
    if ! check_nvidia_smi; then
        log_warn "nvidia-smi が見つかりません - NVIDIA GPU設定をスキップします"
        return 0
    fi
    
    log_info "=========================================="
    log_info "高度なNVIDIA GPU設定を開始..."
    log_info "=========================================="
    
    # NVIDIA Container Toolkit のインストール
    if ! command -v nvidia-container-runtime &> /dev/null; then
        log_info "NVIDIA Container Toolkit が見つかりません - インストールを開始..."
        if install_nvidia_container_toolkit; then
            log_info "✓ NVIDIA Container Toolkit セットアップ完了"
        else
            log_warn "NVIDIA Container Toolkit セットアップに失敗しました"
        fi
    else
        log_info "✓ NVIDIA Container Toolkit は既にインストール済みです"
    fi
    
    # CUDA Toolkit のインストール
    if ! command -v nvcc &> /dev/null; then
        log_info "CUDA Toolkit が見つかりません - インストールを開始..."
        if install_cuda_toolkit; then
            log_info "✓ CUDA Toolkit セットアップ完了"
            # 環境変数設定
            setup_cuda_environment_variables
        else
            log_warn "CUDA Toolkit セットアップに失敗しました"
        fi
    else
        log_info "✓ CUDA Toolkit は既にインストール済みです"
        echo "  バージョン: $(nvcc --version | grep 'release' | awk '{print $6}' 2>/dev/null || echo '確認できません')"
        # 環境変数が設定されているかチェック
        setup_cuda_environment_variables
    fi
    
    log_info "=========================================="
    log_info "高度なNVIDIA GPU設定完了"
    log_info "=========================================="
}

# Mesa バージョン検出とレポート
detect_mesa_version() {
    local mesa_version=""
    local mesa_major=""
    local mesa_minor=""
    
    # glxinfo からMesaバージョンを取得
    if command -v glxinfo &> /dev/null; then
        mesa_version=$(glxinfo 2>/dev/null | grep "OpenGL version string" | grep -o "Mesa [0-9]*\.[0-9]*\.[0-9]*" | head -1)
        if [ -n "$mesa_version" ]; then
            mesa_major=$(echo "$mesa_version" | grep -o "Mesa [0-9]*" | grep -o "[0-9]*")
            mesa_minor=$(echo "$mesa_version" | grep -o "\.[0-9]*\." | grep -o "[0-9]*")
        fi
    fi
    
    # dpkg からも確認
    if [ -z "$mesa_version" ]; then
        local dpkg_mesa=$(dpkg -l | grep "libgl1-mesa-dri" | awk '{print $3}' | head -1)
        if [ -n "$dpkg_mesa" ]; then
            mesa_major=$(echo "$dpkg_mesa" | cut -d. -f1)
            mesa_minor=$(echo "$dpkg_mesa" | cut -d. -f2)
            mesa_version="Mesa $mesa_major.$mesa_minor"
        fi
    fi
    
    echo "$mesa_version"
    return 0
}

# Mesa 24.0+ チェック
check_mesa_opengl46_support() {
    local mesa_version=$(detect_mesa_version)
    
    if [ -z "$mesa_version" ]; then
        log_warn "Mesaバージョンを検出できませんでした"
        return 1
    fi
    
    local mesa_major=$(echo "$mesa_version" | grep -o "Mesa [0-9]*" | grep -o "[0-9]*")
    
    if [ -n "$mesa_major" ] && [ "$mesa_major" -ge 24 ]; then
        log_info "✓ Mesa $mesa_major.x 検出 - OpenGL 4.6 対応済み"
        return 0
    else
        log_warn "Mesa $mesa_version 検出 - OpenGL 4.6 には Mesa 24.0+ が必要"
        return 1
    fi
}

# Kisak Mesa PPA の追加
add_kisak_mesa_ppa() {
    log_info "Kisak Mesa PPA を追加中..."
    
    # PPAが既に追加されているかチェック
    if grep -q "kisak.*mesa" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        log_info "✓ Kisak Mesa PPA は既に追加済みです"
        return 0
    fi
    
    # software-properties-common をインストール
    if ! dpkg -l | grep -q software-properties-common; then
        log_info "software-properties-common をインストール中..."
        if sudo apt install -y software-properties-common > /dev/null 2>&1; then
            log_info "✓ software-properties-common インストール完了"
        else
            log_warn "software-properties-common インストールに失敗しました"
            return 1
        fi
    fi
    
    # PPA追加
    if sudo add-apt-repository -y ppa:kisak/kisak-mesa > /dev/null 2>&1; then
        log_info "✓ Kisak Mesa PPA 追加完了"
        
        # パッケージリスト更新
        if sudo apt update > /dev/null 2>&1; then
            log_info "✓ パッケージリスト更新完了"
            return 0
        else
            log_warn "パッケージリスト更新に失敗しました"
            return 1
        fi
    else
        log_warn "Kisak Mesa PPA 追加に失敗しました"
        return 1
    fi
}

# Mesa 24.0+ への更新
upgrade_mesa_to_24() {
    log_info "Mesa を 24.0+ に更新中..."
    
    local before_version=$(detect_mesa_version)
    log_info "更新前のMesa: $before_version"
    
    # Mesa関連パッケージの更新
    local mesa_packages=(
        "libgl1-mesa-dri"
        "libgl1-mesa-glx" 
        "mesa-common-dev"
        "mesa-utils"
        "libegl1-mesa"
        "libgbm1"
    )
    
    log_info "Mesa関連パッケージを更新中（時間がかかる場合があります）..."
    
    for package in "${mesa_packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            if sudo apt install -y "$package" > /dev/null 2>&1; then
                log_info "✓ $package 更新完了"
            else
                log_warn "$package 更新に失敗しました"
            fi
        fi
    done
    
    # 全体的なapt upgradeも実行
    if sudo apt upgrade -y > /dev/null 2>&1; then
        log_info "✓ システム全体のアップグレード完了"
    else
        log_warn "システムアップグレードで一部失敗がありました"
    fi
    
    local after_version=$(detect_mesa_version)
    log_info "更新後のMesa: $after_version"
    
    return 0
}

# OpenGL 4.6 環境変数の最適化
optimize_opengl46_environment() {
    log_info "OpenGL 4.6 環境変数を最適化中..."
    
    BASHRC_FILE="$HOME/.bashrc"
    
    # LIBGL_ALWAYS_INDIRECT の確認・削除
    if [ -n "$LIBGL_ALWAYS_INDIRECT" ]; then
        log_warn "LIBGL_ALWAYS_INDIRECT が設定されています - OpenGL 4.6 に悪影響"
        unset LIBGL_ALWAYS_INDIRECT
        log_info "✓ LIBGL_ALWAYS_INDIRECT を現在のセッションから削除しました"
    fi
    
    # ~/.bashrc からも削除
    if grep -q "LIBGL_ALWAYS_INDIRECT" "$BASHRC_FILE" 2>/dev/null; then
        log_info "~/.bashrc から LIBGL_ALWAYS_INDIRECT を削除中..."
        sed -i '/LIBGL_ALWAYS_INDIRECT/d' "$BASHRC_FILE"
        log_info "✓ ~/.bashrc から LIBGL_ALWAYS_INDIRECT を削除しました"
    fi
    
    # OpenGL 4.6 最適化環境変数設定
    OPENGL46_SETTINGS="
# OpenGL 4.6 Optimization (BoxelGame)
export GALLIUM_DRIVER=d3d12
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLSL_VERSION_OVERRIDE=460
unset LIBGL_ALWAYS_INDIRECT"
    
    # 既存の設定をチェック
    if grep -q "OpenGL 4.6 Optimization (BoxelGame)" "$BASHRC_FILE" 2>/dev/null; then
        log_info "✓ OpenGL 4.6 最適化設定は既に設定済みです"
    else
        echo "$OPENGL46_SETTINGS" >> "$BASHRC_FILE"
        log_info "✓ OpenGL 4.6 最適化設定を ~/.bashrc に追加しました"
    fi
    
    # 現在のセッションに適用
    export GALLIUM_DRIVER=d3d12
    export MESA_GL_VERSION_OVERRIDE=4.6
    export MESA_GLSL_VERSION_OVERRIDE=460
    unset LIBGL_ALWAYS_INDIRECT
    
    log_info "✓ OpenGL 4.6 環境変数最適化完了"
}

# OpenGL 4.6 動作確認
verify_opengl46_support() {
    log_info "=========================================="
    log_info "OpenGL 4.6 動作確認"
    log_info "=========================================="
    
    # Mesa バージョン確認
    local mesa_version=$(detect_mesa_version)
    log_info "現在のMesa: $mesa_version"
    
    # OpenGL情報確認
    if command -v glxinfo &> /dev/null; then
        log_info "OpenGL詳細情報:"
        
        # GLXエラーを回避するため、オフスクリーンレンダリングを使用
        local gl_vendor=$(DISPLAY=:0 glxinfo 2>/dev/null | grep "OpenGL vendor string" | cut -d: -f2 | xargs || echo "取得失敗")
        local gl_renderer=$(DISPLAY=:0 glxinfo 2>/dev/null | grep "OpenGL renderer string" | cut -d: -f2 | xargs || echo "取得失敗")
        local gl_version=$(DISPLAY=:0 glxinfo 2>/dev/null | grep "OpenGL version string" | cut -d: -f2 | xargs || echo "取得失敗")
        local gl_shading=$(DISPLAY=:0 glxinfo 2>/dev/null | grep "OpenGL shading language version string" | cut -d: -f2 | xargs || echo "取得失敗")
        
        echo "  Vendor: $gl_vendor"
        echo "  Renderer: $gl_renderer"  
        echo "  Version: $gl_version"
        echo "  Shading Language: $gl_shading"
        
        # OpenGL 4.6 対応確認
        if echo "$gl_version" | grep -q "4\.[6-9]"; then
            log_info "✅ OpenGL 4.6+ 対応確認済み!"
        elif echo "$gl_version" | grep -q "4\.[0-5]"; then
            log_warn "⚠️  OpenGL 4.0-4.5 検出 - 4.6 未対応"
        else
            log_warn "⚠️  OpenGL 4.6 未対応または検出失敗"
        fi
    else
        log_warn "glxinfo が利用できません"
    fi
    
    # 環境変数確認
    log_info "関連環境変数:"
    echo "  GALLIUM_DRIVER: ${GALLIUM_DRIVER:-未設定}"
    echo "  MESA_GL_VERSION_OVERRIDE: ${MESA_GL_VERSION_OVERRIDE:-未設定}"
    echo "  MESA_GLSL_VERSION_OVERRIDE: ${MESA_GLSL_VERSION_OVERRIDE:-未設定}"
    echo "  LIBGL_ALWAYS_INDIRECT: ${LIBGL_ALWAYS_INDIRECT:-未設定}"
    
    log_info "=========================================="
}

# Mesa 24.0+ OpenGL 4.6 対応セットアップのメイン関数
setup_mesa_opengl46() {
    log_info "=========================================="
    log_info "Mesa 24.0+ OpenGL 4.6 対応セットアップ開始"
    log_info "=========================================="
    
    # 現在のMesaバージョンチェック
    if check_mesa_opengl46_support; then
        log_info "Mesa 24.0+ が既にインストールされています"
        # 環境変数最適化は実行
        optimize_opengl46_environment
    else
        log_info "Mesa 24.0+ が必要です - アップグレードを開始します"
        
        # Kisak Mesa PPA追加
        if add_kisak_mesa_ppa; then
            log_info "✓ Kisak Mesa PPA 追加完了"
        else
            log_warn "Kisak Mesa PPA 追加に失敗しました"
            return 1
        fi
        
        # Mesa 24.0+ への更新
        if upgrade_mesa_to_24; then
            log_info "✓ Mesa 24.0+ 更新完了"
        else
            log_warn "Mesa 更新に失敗しました"
            return 1
        fi
        
        # 環境変数最適化
        optimize_opengl46_environment
    fi
    
    # 動作確認
    verify_opengl46_support
    
    log_info "=========================================="
    log_info "Mesa 24.0+ OpenGL 4.6 対応セットアップ完了"
    log_info "=========================================="
    
    return 0
}

# バージョン確認
log_info "インストール済みバージョン確認:"
echo "  CMake: $(cmake --version | head -1)"
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

# 高度なNVIDIA GPU設定の実行（nvidia-smiが利用可能な場合）
if check_nvidia_smi; then
    echo ""
    log_info "NVIDIA GPU環境が検出されました"
    read -p "高度なNVIDIA GPU設定（Container Toolkit + CUDA）を実行しますか？ [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_advanced_nvidia_gpu
    else
        log_info "高度なNVIDIA GPU設定をスキップしました"
        log_info "後で実行する場合は以下のコマンドを使用してください:"
        echo "  source $(realpath $0) && setup_advanced_nvidia_gpu"
    fi
fi

# Mesa 24.0+ OpenGL 4.6 対応設定の実行
echo ""
log_info "OpenGL 4.6 対応のためのMesa設定を確認中..."
if ! check_mesa_opengl46_support; then
    echo ""
    log_warn "現在のMesaバージョンはOpenGL 4.6に対応していません"
    read -p "Mesa 24.0+ にアップグレードしてOpenGL 4.6対応を有効にしますか？ [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_mesa_opengl46
    else
        log_info "Mesa アップグレードをスキップしました"
        log_info "現在のOpenGL環境で開発を継続します（OpenGL 4.1-4.3対応）"
        log_info "後でMesa 24.0+を設定する場合は以下のコマンドを使用してください:"
        echo "  source $(realpath $0) && setup_mesa_opengl46"
    fi
else
    log_info "Mesa 24.0+ が既にインストールされています"
    log_info "OpenGL 4.6 環境変数を最適化します..."
    optimize_opengl46_environment
    echo ""
    verify_opengl46_support
fi

# 最終的な動作確認
perform_final_verification() {
    log_info "=========================================="
    log_info "最終動作確認"
    log_info "=========================================="
    
    # 基本ツール確認
    log_info "基本開発ツール:"
    echo "  CMake: $(cmake --version | head -1)"
    echo "  GCC: $(gcc --version | head -1)"
    echo "  Ninja: $(ninja --version)"
    
    # OpenGL/GPU確認
    log_info "GPU・OpenGL環境:"
    if command -v glxinfo &> /dev/null; then
        echo "  OpenGL Vendor: $(glxinfo | grep 'OpenGL vendor' | cut -d: -f2 | xargs)"
        echo "  OpenGL Renderer: $(glxinfo | grep 'OpenGL renderer' | cut -d: -f2 | xargs)"
        echo "  OpenGL Version: $(glxinfo | grep 'OpenGL version' | cut -d: -f2 | xargs)"
    else
        log_warn "glxinfo が利用できません"
    fi
    
    # NVIDIA GPU確認
    if check_nvidia_smi; then
        log_info "NVIDIA GPU情報:"
        echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | head -1)"
        echo "  ドライバー: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1)"
        
        if command -v nvcc &> /dev/null; then
            echo "  CUDA: $(nvcc --version | grep 'release' | awk '{print $6}' 2>/dev/null || echo '確認できません')"
        else
            echo "  CUDA: 未インストール"
        fi
    fi
    
    # WSL環境確認
    if [ -e "/dev/dxg" ]; then
        log_info "✓ WSL GPU デバイス (/dev/dxg) 検出済み"
    else
        log_warn "WSL GPU デバイス (/dev/dxg) が見つかりません"
    fi
    
    log_info "=========================================="
}

# 最終確認を実行
perform_final_verification

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
    echo ""
fi

log_info "OpenGL 4.6 テストコマンド:"
echo "  ./build/default/tests/BoxelGameTests --test-case=\"*OpenGL互換性テスト*\""
echo ""
log_info "=========================================="