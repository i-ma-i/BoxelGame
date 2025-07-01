# Windows最小限セットアップスクリプト

Write-Host "Windows開発環境確認開始..."

# CMakeチェック
if (Get-Command cmake -ErrorAction SilentlyContinue) {
    Write-Host "✓ CMakeが見つかりました"
} else {
    Write-Host "✗ CMakeをインストールしてください"
    Write-Host "  https://cmake.org/download/"
}

# Visual Studioチェック
if (Get-Command msbuild -ErrorAction SilentlyContinue) {
    Write-Host "✓ MSBuildが見つかりました"
} else {
    Write-Host "✗ Visual Studio Build Toolsをインストールしてください"
    Write-Host "  https://visualstudio.microsoft.com/ja/vs/"
}

# Gitチェック
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "✓ Gitが見つかりました"
} else {
    Write-Host "✗ Gitをインストールしてください"
    Write-Host "  https://git-scm.com/download/win"
}

Write-Host ""
Write-Host "Windows開発環境確認完了!"

Write-Host ""
Write-Host "ビルド手順:"
Write-Host "1. Developer Command Prompt を開く"
Write-Host "2. ./scripts/build.sh"
