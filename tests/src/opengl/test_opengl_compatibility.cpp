#include <doctest/doctest.h>
#include <spdlog/spdlog.h>
#include <vector>
#include <string>

// OpenGL関連のインクルード
#include <glad/gl.h>       // GLADを先に読み込み
#define GLFW_INCLUDE_NONE // GLFWにOpenGLヘッダーを含めさせない
#include <GLFW/glfw3.h> // GLFWはGLADの後

namespace BoxelGame {
namespace Test {

struct OpenGLVersion {
    int major;
    int minor;
    int profile; // GLFW_OPENGL_CORE_PROFILE, GLFW_OPENGL_COMPAT_PROFILE, GLFW_OPENGL_ANY_PROFILE
    std::string name;
    
    OpenGLVersion(int maj, int min, int prof, const std::string& n) 
        : major(maj), minor(min), profile(prof), name(n) {}
};

struct TestResult {
    OpenGLVersion version;
    bool success;
    std::string error_message;
    std::string gl_version;
    std::string gl_renderer;
    std::string gl_vendor;
    
    TestResult(const OpenGLVersion& ver) : version(ver), success(false) {}
};

class OpenGLCompatibilityTester {
private:
    static void ErrorCallback(int /*error*/, const char* /*description*/) {
        // GLFWエラーを静的に記録（テスト中のログを抑制）
    }
    
    bool TestOpenGLVersion(const OpenGLVersion& version, TestResult& result) {
        GLFWwindow* window = nullptr;
        
        try {
            // GLFWの初期化（既に初期化済みの場合はスキップ）
            if (!glfwInit()) {
                result.error_message = "GLFW初期化失敗";
                return false;
            }
            
            // OpenGLバージョンとプロファイルを設定
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, version.major);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, version.minor);
            glfwWindowHint(GLFW_OPENGL_PROFILE, version.profile);
            
            // テスト用の小さなウィンドウを作成（非表示）
            glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
            window = glfwCreateWindow(100, 100, "OpenGL Test", nullptr, nullptr);
            
            if (!window) {
                result.error_message = "ウィンドウ作成失敗";
                return false;
            }
            
            // OpenGLコンテキストをアクティブ化
            glfwMakeContextCurrent(window);
            
            // GLADでOpenGL関数をロード
            if (!gladLoadGL(glfwGetProcAddress)) {
                result.error_message = "OpenGL関数ロード失敗";
                glfwDestroyWindow(window);
                return false;
            }
            
            // OpenGL情報を取得
            const char* gl_version = reinterpret_cast<const char*>(glGetString(GL_VERSION));
            const char* gl_renderer = reinterpret_cast<const char*>(glGetString(GL_RENDERER));
            const char* gl_vendor = reinterpret_cast<const char*>(glGetString(GL_VENDOR));
            
            result.gl_version = gl_version ? gl_version : "Unknown";
            result.gl_renderer = gl_renderer ? gl_renderer : "Unknown";
            result.gl_vendor = gl_vendor ? gl_vendor : "Unknown";
            
            // 基本的なOpenGL情報取得テスト完了
            
            // 成功
            result.success = true;
            glfwDestroyWindow(window);
            return true;
            
        } catch (const std::exception& e) {
            result.error_message = "例外発生: " + std::string(e.what());
            if (window) {
                glfwDestroyWindow(window);
            }
            return false;
        } catch (...) {
            result.error_message = "不明な例外発生";
            if (window) {
                glfwDestroyWindow(window);
            }
            return false;
        }
    }
    
public:
    std::vector<TestResult> RunCompatibilityTests() {
        // テスト対象のOpenGLバージョン一覧
        std::vector<OpenGLVersion> versions = {
            // OpenGL 2.x
            {2, 1, GLFW_OPENGL_ANY_PROFILE, "OpenGL 2.1 Any Profile"},
            
            // OpenGL 3.x
            {3, 0, GLFW_OPENGL_ANY_PROFILE, "OpenGL 3.0 Any Profile"},
            {3, 1, GLFW_OPENGL_ANY_PROFILE, "OpenGL 3.1 Any Profile"},
            {3, 2, GLFW_OPENGL_COMPAT_PROFILE, "OpenGL 3.2 Compatibility Profile"},
            {3, 2, GLFW_OPENGL_CORE_PROFILE, "OpenGL 3.2 Core Profile"},
            {3, 3, GLFW_OPENGL_COMPAT_PROFILE, "OpenGL 3.3 Compatibility Profile"},
            {3, 3, GLFW_OPENGL_CORE_PROFILE, "OpenGL 3.3 Core Profile"},
            
            // OpenGL 4.x
            {4, 0, GLFW_OPENGL_COMPAT_PROFILE, "OpenGL 4.0 Compatibility Profile"},
            {4, 0, GLFW_OPENGL_CORE_PROFILE, "OpenGL 4.0 Core Profile"},
            {4, 1, GLFW_OPENGL_COMPAT_PROFILE, "OpenGL 4.1 Compatibility Profile"},
            {4, 1, GLFW_OPENGL_CORE_PROFILE, "OpenGL 4.1 Core Profile"},
            {4, 2, GLFW_OPENGL_COMPAT_PROFILE, "OpenGL 4.2 Compatibility Profile"},
            {4, 2, GLFW_OPENGL_CORE_PROFILE, "OpenGL 4.2 Core Profile"},
            {4, 3, GLFW_OPENGL_COMPAT_PROFILE, "OpenGL 4.3 Compatibility Profile"},
            {4, 3, GLFW_OPENGL_CORE_PROFILE, "OpenGL 4.3 Core Profile"},
            {4, 4, GLFW_OPENGL_COMPAT_PROFILE, "OpenGL 4.4 Compatibility Profile"},
            {4, 4, GLFW_OPENGL_CORE_PROFILE, "OpenGL 4.4 Core Profile"},
            {4, 5, GLFW_OPENGL_COMPAT_PROFILE, "OpenGL 4.5 Compatibility Profile"},
            {4, 5, GLFW_OPENGL_CORE_PROFILE, "OpenGL 4.5 Core Profile"},
            {4, 6, GLFW_OPENGL_COMPAT_PROFILE, "OpenGL 4.6 Compatibility Profile"},
            {4, 6, GLFW_OPENGL_CORE_PROFILE, "OpenGL 4.6 Core Profile"},
        };
        
        std::vector<TestResult> results;
        
        // GLFWエラーコールバックを設定（エラーログを抑制）
        glfwSetErrorCallback(ErrorCallback);
        
        spdlog::info("OpenGL互換性テスト開始 - {} バージョンをテスト中...", versions.size());
        
        for (const auto& version : versions) {
            TestResult result(version);
            TestOpenGLVersion(version, result);
            results.push_back(result);
            
            if (result.success) {
                spdlog::info("✅ {} - 成功", version.name);
                spdlog::info("  実際のバージョン: {}", result.gl_version);
                spdlog::info("  レンダラー: {}", result.gl_renderer);
            } else {
                spdlog::warn("❌ {} - 失敗: {}", version.name, result.error_message);
            }
        }
        
        return results;
    }
    
    void PrintSummary(const std::vector<TestResult>& results) {
        int success_count = 0;
        OpenGLVersion highest_successful(0, 0, GLFW_OPENGL_ANY_PROFILE, "None");
        
        spdlog::info("========================================");
        spdlog::info("OpenGL互換性テスト結果サマリー");
        spdlog::info("========================================");
        
        for (const auto& result : results) {
            if (result.success) {
                success_count++;
                if (result.version.major > highest_successful.major || 
                    (result.version.major == highest_successful.major && 
                     result.version.minor > highest_successful.minor)) {
                    highest_successful = result.version;
                }
            }
        }
        
        spdlog::info("成功: {}/{} バージョン", success_count, results.size());
        
        if (success_count > 0) {
            spdlog::info("最高対応バージョン: {}", highest_successful.name);
        } else {
            spdlog::error("対応するOpenGLバージョンが見つかりませんでした");
        }
        
        spdlog::info("========================================");
    }
};

TEST_CASE("OpenGL互換性テスト - WSL環境での対応状況確認") {
    OpenGLCompatibilityTester tester;
    
    SUBCASE("基本互換性テスト") {
        auto results = tester.RunCompatibilityTests();
        tester.PrintSummary(results);
        
        // 最低限OpenGL 2.1は対応していることを期待
        bool found_working_version = false;
        for (const auto& result : results) {
            if (result.success) {
                found_working_version = true;
                break;
            }
        }
        
        WARN_MESSAGE(found_working_version, "警告: 対応するOpenGLバージョンが見つかりませんでした");
    }
    
    SUBCASE("OpenGL 3.3 Core Profile テスト") {
        TestResult result(OpenGLVersion(3, 3, GLFW_OPENGL_CORE_PROFILE, "OpenGL 3.3 Core Profile"));
        OpenGLCompatibilityTester core_tester;
        
        // 個別テスト実行のためのプライベートメソッドアクセス用
        auto results = core_tester.RunCompatibilityTests();
        
        bool found_33_core = false;
        for (const auto& res : results) {
            if (res.version.major == 3 && res.version.minor == 3 && 
                res.version.profile == GLFW_OPENGL_CORE_PROFILE) {
                found_33_core = res.success;
                if (res.success) {
                    spdlog::info("OpenGL 3.3 Core Profile対応確認済み");
                } else {
                    spdlog::warn("OpenGL 3.3 Core Profile非対応: {}", res.error_message);
                }
                break;
            }
        }
        
        INFO("OpenGL 3.3 Core Profile対応状況: ", found_33_core ? "対応" : "非対応");
    }
    
    SUBCASE("OpenGL 4.6 Core Profile テスト") {
        auto results = tester.RunCompatibilityTests();
        
        bool found_46_core = false;
        for (const auto& res : results) {
            if (res.version.major == 4 && res.version.minor == 6 && 
                res.version.profile == GLFW_OPENGL_CORE_PROFILE) {
                found_46_core = res.success;
                if (res.success) {
                    spdlog::info("OpenGL 4.6 Core Profile対応確認済み");
                    spdlog::info("本来の仕様通りの動作が可能です");
                } else {
                    spdlog::warn("OpenGL 4.6 Core Profile非対応: {}", res.error_message);
                    spdlog::info("代替バージョンでの実装を検討してください");
                }
                break;
            }
        }
        
        INFO("OpenGL 4.6 Core Profile対応状況: ", found_46_core ? "対応" : "非対応");
    }
}

} // namespace Test
} // namespace BoxelGame