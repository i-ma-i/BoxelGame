# BoxelGame - Windows セットアップスクリプト
# このスクリプトは必要な開発ツールの確認とインストールガイドを提供します

# 管理者権限確認
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "このスクリプトは管理者権限で実行してください" -ForegroundColor Red
    Write-Host "PowerShellを管理者として実行し、再度このスクリプトを実行してください" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host "BoxelGame Windows セットアップ" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# 必要ツールの確認
$tools = @{
    "Git" = @{
        Command = "git"
        Version = "git --version"
        InstallUrl = "https://git-scm.com/download/win"
    }
    "CMake" = @{
        Command = "cmake"
        Version = "cmake --version"
        InstallUrl = "https://cmake.org/download/"
        MinVersion = "3.19"
    }
    "Visual Studio Build Tools" = @{
        Command = "cl"
        Version = "cl"
        InstallUrl = "https://visualstudio.microsoft.com/ja/vs/older-downloads/"
        Note = "Visual Studio 2022 Community または Build Tools が必要"
    }
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
    
    Write-Host "`n特に重要: Visual Studio 2022 のインストール" -ForegroundColor Yellow
    Write-Host "1. https://visualstudio.microsoft.com/ja/vs/ にアクセス" -ForegroundColor White
    Write-Host "2. Community版（無料）をダウンロード" -ForegroundColor White
    Write-Host "3. インストール時に以下のワークロードを選択:" -ForegroundColor White
    Write-Host "   - C++ によるデスクトップ開発" -ForegroundColor White
    Write-Host "   - Windows 10/11 SDK" -ForegroundColor White
    
    Write-Host "`nChocolatey での一括インストール（推奨）:" -ForegroundColor Green
    Write-Host "1. 管理者PowerShellでChocolateyをインストール:" -ForegroundColor White
    Write-Host "   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor Gray
    Write-Host "2. 必要ツールをインストール:" -ForegroundColor White
    Write-Host "   choco install git cmake visualstudio2022community --package-parameters `"--add Microsoft.VisualStudio.Workload.NativeDesktop`"" -ForegroundColor Gray
    
} else {
    Write-Host "`n=========================================" -ForegroundColor Green
    Write-Host "✓ すべての必要ツールが揃っています！" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
}

# ビルド手順の表示
Write-Host "`nビルド手順:" -ForegroundColor Green
Write-Host "1. Developer Command Prompt for VS 2022 を開く" -ForegroundColor White
Write-Host "2. プロジェクトディレクトリに移動:" -ForegroundColor White
Write-Host "   cd `"$(Split-Path -Parent $PSScriptRoot)`"" -ForegroundColor Gray
Write-Host "3. CMake設定:" -ForegroundColor White
Write-Host "   cmake --preset windows-debug" -ForegroundColor Gray
Write-Host "4. ビルド実行:" -ForegroundColor White
Write-Host "   cmake --build build/windows-debug --config Debug" -ForegroundColor Gray
Write-Host "5. テスト実行:" -ForegroundColor White
Write-Host "   .\build\windows-debug\tests\Debug\BoxelGameTests.exe" -ForegroundColor Gray

Write-Host "`n注意事項:" -ForegroundColor Yellow
Write-Host "- 必ず Developer Command Prompt または PowerShell (開発者) を使用してください" -ForegroundColor White
Write-Host "- 通常のPowerShellやコマンドプロンプトではビルドが失敗する可能性があります" -ForegroundColor White

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "セットアップ確認完了" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Read-Host "Press Enter to exit"