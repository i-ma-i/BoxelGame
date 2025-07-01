#include <doctest/doctest.h>
#include <spdlog/spdlog.h>
#include <vector>
#include <string>
#include <map>
#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <sstream>

namespace BoxelGame {
namespace Test {

struct SystemGPUInfo {
    std::string pci_id;
    std::string vendor;
    std::string device_name;
    std::string driver;
    bool is_nvidia;
    bool is_amd;
    bool is_intel;
    
    SystemGPUInfo() : is_nvidia(false), is_amd(false), is_intel(false) {}
};

struct WSLInfo {
    std::string wsl_version;
    std::string kernel_version;
    std::string windows_version;
    bool gpu_passthrough_available;
    bool cuda_available;
    bool vulkan_available;
    
    WSLInfo() : gpu_passthrough_available(false), cuda_available(false), vulkan_available(false) {}
};

class SystemGPUDetector {
private:
    std::string ExecuteCommand(const std::string& command) {
        std::string result;
        char buffer[128];
        
        try {
            FILE* pipe = popen(command.c_str(), "r");
            if (!pipe) {
                return "";
            }
            
            while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
                result += buffer;
            }
            
            pclose(pipe);
        } catch (...) {
            return "";
        }
        
        return result;
    }
    
    std::vector<std::string> ReadFileLines(const std::string& filepath) {
        std::vector<std::string> lines;
        std::ifstream file(filepath);
        std::string line;
        
        while (std::getline(file, line)) {
            if (!line.empty()) {
                lines.push_back(line);
            }
        }
        
        return lines;
    }
    
public:
    std::vector<SystemGPUInfo> DetectSystemGPUs() {
        std::vector<SystemGPUInfo> gpus;
        
        spdlog::info("========================================");
        spdlog::info("システムGPU検出開始");
        spdlog::info("========================================");
        
        // 1. lspci でPCIデバイス一覧を取得
        spdlog::info("1. lspci コマンドでPCIデバイスを検索中...");
        std::string lspci_output = ExecuteCommand("lspci -nn | grep -i 'vga\\|3d\\|display'");
        
        if (!lspci_output.empty()) {
            spdlog::info("検出されたディスプレイデバイス:");
            std::istringstream iss(lspci_output);
            std::string line;
            
            while (std::getline(iss, line)) {
                SystemGPUInfo gpu;
                gpu.pci_id = line.substr(0, line.find(' '));
                
                // ベンダーとデバイス名を抽出
                if (line.find("NVIDIA") != std::string::npos || line.find("GeForce") != std::string::npos) {
                    gpu.vendor = "NVIDIA";
                    gpu.is_nvidia = true;
                } else if (line.find("AMD") != std::string::npos || line.find("Radeon") != std::string::npos) {
                    gpu.vendor = "AMD";
                    gpu.is_amd = true;
                } else if (line.find("Intel") != std::string::npos) {
                    gpu.vendor = "Intel";
                    gpu.is_intel = true;
                } else {
                    gpu.vendor = "Unknown";
                }
                
                gpu.device_name = line;
                gpus.push_back(gpu);
                
                spdlog::info("  - {}", line);
            }
        } else {
            spdlog::warn("lspci でディスプレイデバイスが検出されませんでした");
        }
        
        // 2. NVIDIA GPU確認（nvidia-smiのみ）
        spdlog::info("2. nvidia-smi で NVIDIA GPU を確認中...");
        std::string nvidia_smi = ExecuteCommand("nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits 2>/dev/null");
        if (!nvidia_smi.empty()) {
            spdlog::info("✓ NVIDIA GPU検出:");
            std::istringstream iss(nvidia_smi);
            std::string line;
            while (std::getline(iss, line)) {
                spdlog::info("  {}", line);
            }
        } else {
            spdlog::warn("NVIDIA GPU が検出されませんでした");
        }
        
        // 3. OpenGL情報（簡略版）
        spdlog::info("3. OpenGL対応確認中...");
        std::string glxinfo = ExecuteCommand("glxinfo 2>/dev/null | grep 'OpenGL version'");
        if (!glxinfo.empty()) {
            auto version_pos = glxinfo.find(":");
            if (version_pos != std::string::npos) {
                std::string version = glxinfo.substr(version_pos + 1);
                version.erase(0, version.find_first_not_of(" \t"));
                spdlog::info("✓ OpenGL対応: {}", version);
            }
        } else {
            spdlog::warn("OpenGL情報を取得できませんでした");
        }
        
        spdlog::info("========================================");
        return gpus;
    }
    
    WSLInfo DetectWSLInfo() {
        WSLInfo wsl_info;
        
        spdlog::info("========================================");
        spdlog::info("WSL環境情報検出開始");
        spdlog::info("========================================");
        
        // 1. WSL バージョン確認
        std::string wsl_version = ExecuteCommand("cat /proc/version");
        if (wsl_version.find("Microsoft") != std::string::npos || wsl_version.find("WSL") != std::string::npos) {
            wsl_info.wsl_version = wsl_version;
            spdlog::info("WSL環境確認済み:");
            spdlog::info("  {}", wsl_version.substr(0, 100) + (wsl_version.length() > 100 ? "..." : ""));
        } else {
            spdlog::info("ネイティブLinux環境");
        }
        
        // 2. カーネルバージョン
        wsl_info.kernel_version = ExecuteCommand("uname -r");
        spdlog::info("カーネルバージョン: {}", wsl_info.kernel_version);
        
        // 3. GPU パススルー対応確認
        std::string dxgkrnl = ExecuteCommand("lsmod | grep dxgkrnl");
        if (!dxgkrnl.empty()) {
            wsl_info.gpu_passthrough_available = true;
            spdlog::info("GPU パススルー対応: 有効");
            spdlog::info("  dxgkrnl モジュール検出: {}", dxgkrnl);
        } else {
            spdlog::warn("GPU パススルー対応: 無効");
        }
        
        // 4. CUDA 対応確認
        std::string nvcc_version = ExecuteCommand("nvcc --version 2>/dev/null");
        if (!nvcc_version.empty()) {
            wsl_info.cuda_available = true;
            spdlog::info("CUDA対応: 有効");
            spdlog::info("  nvcc バージョン情報検出");
        } else {
            spdlog::warn("CUDA対応: 無効 (nvcc not found)");
        }
        
        // 5. Vulkan 対応確認
        std::string vulkan_devices = ExecuteCommand("vulkaninfo --summary 2>/dev/null | grep 'deviceName'");
        if (!vulkan_devices.empty()) {
            wsl_info.vulkan_available = true;
            spdlog::info("Vulkan対応: 有効");
        } else {
            spdlog::warn("Vulkan対応: 無効");
        }
        
        // 6. 重要な環境変数チェック（最小限）
        spdlog::info("重要な環境変数:");
        std::vector<std::string> critical_vars = {
            "DISPLAY", "WAYLAND_DISPLAY", 
            "__NV_PRIME_RENDER_OFFLOAD", "__GLX_VENDOR_LIBRARY_NAME",
            "GALLIUM_DRIVER"
        };
        
        for (const auto& var : critical_vars) {
            const char* value = std::getenv(var.c_str());
            if (value) {  // 設定されている場合のみ表示
                spdlog::info("  {}: {}", var, value);
            }
        }
        
        // 7. /dev/dxg の存在確認 (WSL GPU パススルー用デバイス)
        std::string dxg_device = ExecuteCommand("ls -la /dev/dxg* 2>/dev/null");
        if (!dxg_device.empty()) {
            spdlog::info("WSL GPU デバイス発見:");
            spdlog::info("  {}", dxg_device);
        } else {
            spdlog::warn("WSL GPU デバイス (/dev/dxg*) が見つかりません");
        }
        
        spdlog::info("========================================");
        return wsl_info;
    }
    
    void AnalyzeGPUDetectionResults(const std::vector<SystemGPUInfo>& gpus, const WSLInfo& wsl_info) {
        spdlog::info("========================================");
        spdlog::info("GPU検出結果分析");
        spdlog::info("========================================");
        
        if (gpus.empty()) {
            spdlog::error("システムレベルでGPUが検出されませんでした");
            return;
        }
        
        // GPU統計
        int nvidia_count = 0, amd_count = 0, intel_count = 0;
        for (const auto& gpu : gpus) {
            if (gpu.is_nvidia) nvidia_count++;
            if (gpu.is_amd) amd_count++;
            if (gpu.is_intel) intel_count++;
        }
        
        spdlog::info("検出されたGPU統計:");
        spdlog::info("  NVIDIA GPU: {} 個", nvidia_count);
        spdlog::info("  AMD GPU: {} 個", amd_count);
        spdlog::info("  Intel GPU: {} 個", intel_count);
        spdlog::info("  合計: {} 個", gpus.size());
        
        // NVIDIA GPU が検出されているが OpenGL で使用できない理由を分析
        if (nvidia_count > 0) {
            spdlog::info("NVIDIA GPU検出済み - OpenGL使用不可の原因分析:");
            
            if (!wsl_info.gpu_passthrough_available) {
                spdlog::warn("  - WSL GPU パススルーが無効");
                spdlog::info("    解決方法: Windows側でGPU仮想化を有効にし、WSL2でGPU対応を設定");
            }
            
            if (!wsl_info.cuda_available) {
                spdlog::warn("  - CUDA toolkit が未インストール");
                spdlog::info("    解決方法: nvidia-cuda-toolkit をインストール");
            }
            
            const char* libgl_software = std::getenv("LIBGL_ALWAYS_SOFTWARE");
            if (libgl_software && std::string(libgl_software) == "1") {
                spdlog::warn("  - LIBGL_ALWAYS_SOFTWARE=1 によりソフトウェア描画が強制されています");
                spdlog::info("    解決方法: unset LIBGL_ALWAYS_SOFTWARE");
            }
        } else {
            spdlog::info("NVIDIA GPUがシステムレベルで検出されていません");
            spdlog::info("可能な原因:");
            spdlog::info("  - WSL環境でNVIDIA GPUが無効");
            spdlog::info("  - Windows側でWSL GPU共有が無効");
            spdlog::info("  - lspci でのPCIデバイス列挙制限");
        }
        
        spdlog::info("========================================");
    }
    
    void RecommendSetupSteps() {
        spdlog::info("========================================");
        spdlog::info("NVIDIA GPU を WSL で使用するための推奨設定手順");
        spdlog::info("========================================");
        
        spdlog::info("【Windows側での設定】");
        spdlog::info("1. NVIDIA Game Ready Driver (最新版) をインストール");
        spdlog::info("2. WSL2 GPU サポートを有効化:");
        spdlog::info("   - Windows の設定 > アプリ > オプション機能");
        spdlog::info("   - 'Windows Subsystem for Linux' を有効");
        spdlog::info("   - 'Virtual Machine Platform' を有効");
        spdlog::info("3. wsl --update でWSLを最新版に更新");
        
        spdlog::info("【WSL側での設定】");
        spdlog::info("1. NVIDIA Container Toolkit をインストール:");
        spdlog::info("   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -");
        spdlog::info("   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)");
        spdlog::info("   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list");
        spdlog::info("   sudo apt update && sudo apt install -y nvidia-docker2");
        
        spdlog::info("2. 必要なパッケージをインストール:");
        spdlog::info("   sudo apt install -y nvidia-cuda-toolkit mesa-utils vulkan-tools");
        
        spdlog::info("3. 環境変数を設定:");
        spdlog::info("   export __NV_PRIME_RENDER_OFFLOAD=1");
        spdlog::info("   export __GLX_VENDOR_LIBRARY_NAME=nvidia");
        
        spdlog::info("4. 動作確認:");
        spdlog::info("   nvidia-smi (NVIDIA GPU情報表示)");
        spdlog::info("   glxinfo | grep NVIDIA (OpenGL NVIDIA 使用確認)");
        
        spdlog::info("========================================");
    }
};

TEST_CASE("システムGPU検出テスト - NVIDIA GPU 検出状況") {
    SystemGPUDetector detector;
    
    SUBCASE("統合分析") {
        auto gpus = detector.DetectSystemGPUs();
        auto wsl_info = detector.DetectWSLInfo();
        
        // GPU検出状況
        bool found_any_gpu = !gpus.empty();
        WARN_MESSAGE(found_any_gpu, "警告: システムレベルでGPUが検出されませんでした");
        
        // NVIDIA GPU の検出状況をレポート
        bool found_nvidia = false;
        for (const auto& gpu : gpus) {
            if (gpu.is_nvidia) {
                found_nvidia = true;
                spdlog::info("NVIDIA GPU検出: {}", gpu.device_name);
                break;
            }
        }
        
        // 総合分析（重複を避けるため1回のみ実行）
        detector.AnalyzeGPUDetectionResults(gpus, wsl_info);
        
        spdlog::info("✅ システムGPU検出テスト完了");
        INFO("NVIDIA GPU検出状況: ", found_nvidia ? "検出" : "未検出");
        INFO("WSL GPU パススルー: ", wsl_info.gpu_passthrough_available ? "有効" : "無効");
        INFO("CUDA対応: ", wsl_info.cuda_available ? "有効" : "無効");
        INFO("Vulkan対応: ", wsl_info.vulkan_available ? "有効" : "無効");
    }
}

} // namespace Test
} // namespace BoxelGame