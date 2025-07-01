# BoxelGame - Windows セットアップスクリプト

# 管理者権限確認
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "このスクリプトは管理者権限で実行してください" -ForegroundColor Red
    Write-Host "PowerShellを管理者として実行し、再度このスクリプトを実行してください" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host "BoxelGame Windows セットアップ"             -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# 必要ツール確認
$tools = @{
    "Git" = @{ Command = "git"; Version = "git --version"; InstallUrl = "https://git-scm.com/download/win" }
    "CMake" = @{ Command = "cmake"; Version = "cmake --version"; InstallUrl = "https://cmake.org/download/" }
    "Visual Studio" = @{ Command = "cl"; InstallUrl = "https://visualstudio.microsoft.com/ja/vs/" }
}

$missing_tools = @()

foreach ($tool in $tools.Keys) {
    Write-Host "`n[$tool を確認中...]" -ForegroundColor Cyan
    
    try {
        if ($tools[$tool].Command -eq "cl") {
            # Visual Studio Build Tools の確認
            $vsInstallPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC"
            if (-not (Test-Path $vsInstallPath)) {
                $vsInstallPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC"
            }
            
            if (Test-Path $vsInstallPath) {
                Write-Host "  ✓ $tool が見つかりました" -ForegroundColor Green
                $latestVersion = Get-ChildItem $vsInstallPath | Sort-Object Name -Descending | Select-Object -First 1
                Write-Host "    バージョン: $($latestVersion.Name)" -ForegroundColor Gray
            } else {
                throw "Not found"
            }
        } else {
            $output = Invoke-Expression $tools[$tool].Version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ $tool が見つかりました" -ForegroundColor Green
                Write-Host "    $($output.Split("`n")[0])" -ForegroundColor Gray
            } else {
                throw "Command failed"
            }
        }
    }
    catch {
        Write-Host "  ✗ $tool が見つかりません" -ForegroundColor Red
        $missing_tools += $tool
    }
}

# インストールガイド
if ($missing_tools.Count -gt 0) {
    Write-Host "`n=========================================" -ForegroundColor Yellow
    Write-Host "不足しているツールのインストールガイド" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    
    foreach ($tool in $missing_tools) {
        Write-Host "`n[$tool]" -ForegroundColor Red
        Write-Host "  ダウンロード: $($tools[$tool].InstallUrl)" -ForegroundColor Cyan
        if ($tools[$tool].Note) {
            Write-Host "  注意: $($tools[$tool].Note)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nVisual Studio 2022 Communityをインストール" -ForegroundColor Yellow
    Write-Host "C++デスクトップ開発ワークロードを選択" -ForegroundColor White
    
} else {
    Write-Host "`n=========================================" -ForegroundColor Green
    Write-Host "✓ すべての必要ツールが揃っています！" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
}

# ビルド手順
Write-Host "`nビルド手順:" -ForegroundColor Green
Write-Host "1. Developer Command Prompt でプロジェクトディレクトリに移動" -ForegroundColor White
Write-Host "2. .\scripts\build.sh" -ForegroundColor Gray
Write-Host "3. .\scripts\test.sh" -ForegroundColor Gray

Write-Host "`n注意: Developer Command Prompt で実行してください" -ForegroundColor Yellow

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "セットアップ確認完了" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Read-Host "Press Enter to exit"