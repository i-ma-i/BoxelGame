#include <doctest/doctest.h>
#include <spdlog/spdlog.h>
#include <vector>
#include <string>
#include <map>
#include <algorithm>
#include <cstdlib>

// OpenGL関連のインクルード
#include <glad.h>       // GLADを先に読み込み
#define GLFW_INCLUDE_NONE // GLFWにOpenGLヘッダーを含めさせない
#include <GLFW/glfw3.h> // GLFWはGLADの後

namespace BoxelGame {
namespace Test {

struct GPUInfo {
    std::string name;
    std::string vendor;
    std::string renderer;
    std::string version;
    std::string driver;
    int device_id;
    bool is_discrete;
    
    GPUInfo() : device_id(-1), is_discrete(false) {}
};

struct TestConfig {
    std::string method_name;
    std::vector<std::pair<int, int>> hints; // GLFW hint pairs
    std::string description;
    
    TestConfig(const std::string& name, const std::vector<std::pair<int, int>>& h, const std::string& desc)
        : method_name(name), hints(h), description(desc) {}
};

class GPUSelectionTester {
private:
    static void ErrorCallback(int /*error*/, const char* /*description*/) {
        // GLFWエラーを記録（詳細なログは後で実装）
    }
    
    bool TestGPUWithConfig(const TestConfig& config, GPUInfo& gpu_info) {
        GLFWwindow* window = nullptr;
        
        try {
            // GLFWの初期化
            if (!glfwInit()) {
                spdlog::error("GLFW初期化失敗: {}", config.method_name);
                return false;
            }
            
            // 設定されたヒントを適用
            for (const auto& hint : config.hints) {
                glfwWindowHint(hint.first, hint.second);
            }
            
            // テスト用ウィンドウ作成（非表示）
            glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
            window = glfwCreateWindow(100, 100, "GPU Test", nullptr, nullptr);
            
            if (!window) {
                spdlog::warn("ウィンドウ作成失敗: {}", config.method_name);
                return false;
            }
            
            // OpenGLコンテキストを作成
            glfwMakeContextCurrent(window);
            
            // GLADでOpenGL関数をロード
            if (!gladLoadGL()) {
                spdlog::error("OpenGL関数ロード失敗: {}", config.method_name);
                glfwDestroyWindow(window);
                return false;
            }
            
            // GPU情報を取得
            const char* vendor = reinterpret_cast<const char*>(glGetString(GL_VENDOR));
            const char* renderer = reinterpret_cast<const char*>(glGetString(GL_RENDERER));
            const char* version = reinterpret_cast<const char*>(glGetString(GL_VERSION));
            
            // シェーディング言語バージョン（存在する場合のみ）
            const char* shading_version = nullptr;
            if (glGetString) {
                // OpenGL 2.0以降で利用可能
                shading_version = reinterpret_cast<const char*>(glGetString(0x8B8C)); // GL_SHADING_LANGUAGE_VERSION
            }
            
            gpu_info.vendor = vendor ? vendor : "Unknown";
            gpu_info.renderer = renderer ? renderer : "Unknown";
            gpu_info.version = version ? version : "Unknown";
            gpu_info.driver = shading_version ? shading_version : "Unknown";
            gpu_info.name = config.method_name;
            
            // ディスクリートGPUかどうかの推定
            std::string vendor_lower = gpu_info.vendor;
            std::transform(vendor_lower.begin(), vendor_lower.end(), vendor_lower.begin(), ::tolower);
            std::string renderer_lower = gpu_info.renderer;
            std::transform(renderer_lower.begin(), renderer_lower.end(), renderer_lower.begin(), ::tolower);
            
            gpu_info.is_discrete = (vendor_lower.find("nvidia") != std::string::npos) ||
                                   (vendor_lower.find("amd") != std::string::npos) ||
                                   (renderer_lower.find("radeon") != std::string::npos) ||
                                   (renderer_lower.find("geforce") != std::string::npos) ||
                                   (renderer_lower.find("quadro") != std::string::npos);
            
            glfwDestroyWindow(window);
            return true;
            
        } catch (const std::exception& e) {
            spdlog::error("例外発生 {}: {}", config.method_name, e.what());
            if (window) {
                glfwDestroyWindow(window);
            }
            return false;
        }
    }
    
public:
    std::vector<GPUInfo> RunGPUSelectionTests() {
        std::vector<TestConfig> configs = {
            // デフォルト設定
            TestConfig("Default GPU", {}, "システムデフォルトGPU"),
            
            // OpenGL Core Profile設定
            TestConfig("OpenGL 3.3 Core", {
                {GLFW_CONTEXT_VERSION_MAJOR, 3},
                {GLFW_CONTEXT_VERSION_MINOR, 3},
                {GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE}
            }, "OpenGL 3.3 Core Profile"),
            
            TestConfig("OpenGL 4.1 Core", {
                {GLFW_CONTEXT_VERSION_MAJOR, 4},
                {GLFW_CONTEXT_VERSION_MINOR, 1},
                {GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE}
            }, "OpenGL 4.1 Core Profile"),
            
            TestConfig("OpenGL 4.6 Core", {
                {GLFW_CONTEXT_VERSION_MAJOR, 4},
                {GLFW_CONTEXT_VERSION_MINOR, 6},
                {GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE}
            }, "OpenGL 4.6 Core Profile"),
            
            // Compatibility Profile設定
            TestConfig("OpenGL 4.1 Compat", {
                {GLFW_CONTEXT_VERSION_MAJOR, 4},
                {GLFW_CONTEXT_VERSION_MINOR, 1},
                {GLFW_OPENGL_PROFILE, GLFW_OPENGL_COMPAT_PROFILE}
            }, "OpenGL 4.1 Compatibility Profile"),
            
            TestConfig("OpenGL 4.6 Compat", {
                {GLFW_CONTEXT_VERSION_MAJOR, 4},
                {GLFW_CONTEXT_VERSION_MINOR, 6},
                {GLFW_OPENGL_PROFILE, GLFW_OPENGL_COMPAT_PROFILE}
            }, "OpenGL 4.6 Compatibility Profile"),
            
            // 高性能GPU要求設定
            TestConfig("High Performance", {
                {GLFW_CONTEXT_VERSION_MAJOR, 4},
                {GLFW_CONTEXT_VERSION_MINOR, 6},
                {GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE},
                {GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE}
            }, "高性能GPU要求設定"),
            
            // デバッグコンテキスト
            TestConfig("Debug Context", {
                {GLFW_CONTEXT_VERSION_MAJOR, 4},
                {GLFW_CONTEXT_VERSION_MINOR, 1},
                {GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE},
                {GLFW_OPENGL_DEBUG_CONTEXT, GLFW_TRUE}
            }, "デバッグコンテキスト"),
        };
        
        std::vector<GPUInfo> gpu_results;
        
        // GLFWエラーコールバックを設定
        glfwSetErrorCallback(ErrorCallback);
        
        spdlog::info("========================================");
        spdlog::info("GPU選択テスト開始 - {} 設定をテスト中...", configs.size());
        spdlog::info("========================================");
        
        for (const auto& config : configs) {
            GPUInfo gpu_info;
            bool success = TestGPUWithConfig(config, gpu_info);
            
            if (success) {
                gpu_results.push_back(gpu_info);
                spdlog::info("✅ {} - 成功", config.method_name);
                spdlog::info("  ベンダー: {}", gpu_info.vendor);
                spdlog::info("  レンダラー: {}", gpu_info.renderer);
                spdlog::info("  OpenGLバージョン: {}", gpu_info.version);
                spdlog::info("  ディスクリートGPU: {}", gpu_info.is_discrete ? "Yes" : "No");
                spdlog::info("  説明: {}", config.description);
            } else {
                spdlog::warn("❌ {} - 失敗", config.method_name);
                spdlog::warn("  説明: {}", config.description);
            }
            spdlog::info("----------------------------------------");
        }
        
        return gpu_results;
    }
    
    void AnalyzeGPUResults(const std::vector<GPUInfo>& results) {
        spdlog::info("========================================");
        spdlog::info("GPU分析結果");
        spdlog::info("========================================");
        
        if (results.empty()) {
            spdlog::error("利用可能なGPUが見つかりませんでした");
            return;
        }
        
        // ユニークGPUの検出
        std::map<std::string, std::vector<std::string>> gpu_map;
        for (const auto& gpu : results) {
            std::string key = gpu.vendor + " - " + gpu.renderer;
            gpu_map[key].push_back(gpu.name);
        }
        
        spdlog::info("検出されたユニークGPU: {} 個", gpu_map.size());
        
        for (const auto& [gpu_id, methods] : gpu_map) {
            spdlog::info("GPU: {}", gpu_id);
            spdlog::info("  対応設定数: {}", methods.size());
            for (const auto& method : methods) {
                spdlog::info("    - {}", method);
            }
        }
        
        // ディスクリートGPU検出
        bool found_discrete = false;
        for (const auto& gpu : results) {
            if (gpu.is_discrete) {
                found_discrete = true;
                spdlog::info("ディスクリートGPU検出: {} - {}", gpu.vendor, gpu.renderer);
                break;
            }
        }
        
        if (!found_discrete) {
            spdlog::warn("ディスクリートGPUが検出されませんでした");
            spdlog::info("統合GPU環境での動作となります");
        }
        
        // 最高OpenGLバージョンの検出
        std::string highest_version;
        std::string best_gpu;
        for (const auto& gpu : results) {
            if (gpu.version > highest_version) {
                highest_version = gpu.version;
                best_gpu = gpu.renderer;
            }
        }
        
        spdlog::info("最高OpenGLバージョン: {}", highest_version);
        spdlog::info("最良GPU: {}", best_gpu);
        
        spdlog::info("========================================");
    }
    
    void CheckEnvironmentVariables() {
        spdlog::info("========================================");
        spdlog::info("GPU関連環境変数チェック");
        spdlog::info("========================================");
        
        std::vector<std::string> critical_vars = {
            "__NV_PRIME_RENDER_OFFLOAD",
            "__GLX_VENDOR_LIBRARY_NAME", 
            "DRI_PRIME",
            "DISPLAY",
            "WAYLAND_DISPLAY"
        };
        
        for (const auto& var : critical_vars) {
            const char* value = std::getenv(var.c_str());
            spdlog::info("{}: {}", var, value ? value : "(未設定)");
        }
        
        spdlog::info("========================================");
    }
};

TEST_CASE("GPU選択テスト - GLFWプログラム的制御") {
    GPUSelectionTester tester;
    
    SUBCASE("環境変数確認") {
        tester.CheckEnvironmentVariables();
    }
    
    SUBCASE("GPU選択テスト実行") {
        auto results = tester.RunGPUSelectionTests();
        tester.AnalyzeGPUResults(results);
        
        // 少なくとも1つのGPU設定が動作することを確認
        bool found_working_gpu = !results.empty();
        WARN_MESSAGE(found_working_gpu, "警告: 動作するGPU設定が見つかりませんでした");
        
        if (found_working_gpu) {
            spdlog::info("GPU選択テスト完了 - {} 設定が利用可能", results.size());
        }
    }
    
    SUBCASE("高性能GPU検出テスト") {
        auto results = tester.RunGPUSelectionTests();
        
        bool found_discrete = false;
        for (const auto& gpu : results) {
            if (gpu.is_discrete) {
                found_discrete = true;
                spdlog::info("高性能GPU発見: {} - {}", gpu.vendor, gpu.renderer);
                break;
            }
        }
        
        if (!found_discrete) {
            spdlog::warn("高性能GPUが検出されませんでした");
            spdlog::info("統合GPU環境での開発となります");
        }
        
        INFO("高性能GPU検出状況: ", found_discrete ? "検出" : "未検出");
    }
}

} // namespace Test
} // namespace BoxelGame