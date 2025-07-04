#include "core/Window.hpp"
#include <glad/gl.h>       // GLADを先に読み込み
#define GLFW_INCLUDE_NONE // GLFWにOpenGLヘッダーを含めさせない
#include <GLFW/glfw3.h> // GLFWはGLADの後
#include <spdlog/spdlog.h>

namespace BoxelGame {

Window::Window(int width, int height, const std::string& title)
    : m_window(nullptr), m_width(width), m_height(height), m_title(title) {
    
    try {
        spdlog::info("ウィンドウ初期化開始: {}x{} \"{}\"", width, height, title);
        
        InitializeGLFW();
        InitializeWindow();
        InitializeOpenGL();
        SetupCallbacks();
        
        spdlog::info("ウィンドウ初期化完了");
        
    } catch (const WindowException&) {
        // ウィンドウ例外は再スロー
        throw;
    } catch (const std::exception& e) {
        throw WindowException("初期化中にエラーが発生: " + std::string(e.what()));
    } catch (...) {
        throw WindowException("初期化中に不明なエラーが発生");
    }
}

Window::~Window() {
    spdlog::info("ウィンドウを破棄しています...");
    
    if (m_window) {
        glfwDestroyWindow(m_window);
        m_window = nullptr;
    }
    
    glfwTerminate();
    spdlog::info("ウィンドウ破棄完了");
}

bool Window::ShouldClose() const {
    return m_window && glfwWindowShouldClose(m_window);
}

void Window::SwapBuffers() {
    if (m_window) {
        glfwSwapBuffers(m_window);
    }
}

void Window::PollEvents() {
    glfwPollEvents();
}

void Window::GetFramebufferSize(int& width, int& height) const {
    if (m_window) {
        glfwGetFramebufferSize(m_window, &width, &height);
    } else {
        width = m_width;
        height = m_height;
    }
}

void Window::InitializeGLFW() {
    glfwSetErrorCallback(ErrorCallback);
    
    if (!glfwInit()) {
        throw WindowException("GLFWの初期化に失敗");
    }
    
    // OpenGL 4.1 Core Profile設定（WSL互換性のため）
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);
    
    // 統一されたウィンドウ装飾設定
    glfwWindowHint(GLFW_DECORATED, GLFW_TRUE);         // タイトルバーと装飾を表示
    glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);         // リサイズ可能
    glfwWindowHint(GLFW_MAXIMIZED, GLFW_FALSE);        // 最大化状態で開始しない
    glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE);           // ウィンドウを表示
    glfwWindowHint(GLFW_FOCUSED, GLFW_TRUE);           // フォーカスを取得
    glfwWindowHint(GLFW_AUTO_ICONIFY, GLFW_FALSE);     // フォーカス失時の自動最小化を無効
    glfwWindowHint(GLFW_FOCUS_ON_SHOW, GLFW_TRUE);     // 表示時にフォーカスを取得
    
    // レンダリング設定
    glfwWindowHint(GLFW_DOUBLEBUFFER, GLFW_TRUE);      // ダブルバッファリング
    
    // プラットフォーム固有設定
#ifdef WIN32
    glfwWindowHint(GLFW_SCALE_TO_MONITOR, GLFW_TRUE);  // DPIスケーリング対応
    glfwWindowHint(GLFW_WIN32_KEYBOARD_MENU, GLFW_FALSE); // Alt+F4等のキーボードメニュー無効
#endif
    
    spdlog::info("GLFW初期化完了 - OpenGL 4.1 Core Profile");
}

void Window::InitializeWindow() {
    m_window = glfwCreateWindow(m_width, m_height, m_title.c_str(), nullptr, nullptr);
    if (!m_window) {
        // GLFWエラーの詳細情報を取得
        const char* description;
        int error_code = glfwGetError(&description);
        
        std::string error_details = "ウィンドウの作成に失敗";
        if (error_code != GLFW_NO_ERROR) {
            error_details += " - GLFWエラー " + std::to_string(error_code);
            if (description) {
                error_details += ": " + std::string(description);
            }
        }
        
        // 推奨される解決策を追加
        error_details += "\n推奨解決策:\n";
        error_details += "  - グラフィックドライバーを最新版に更新\n";
        error_details += "  - OpenGL 4.1対応を確認\n";
        error_details += "  - 統合グラフィック/専用グラフィック設定を確認";
        
        throw WindowException(error_details);
    }
    
    glfwMakeContextCurrent(m_window);
    glfwSwapInterval(1); // VSync有効
    
    spdlog::info("ウィンドウ作成完了");
}

void Window::InitializeOpenGL() {
    // GLコンテキストが有効か確認
    if (!glfwGetCurrentContext()) {
        throw WindowException("OpenGL初期化失敗: GLコンテキストが無効");
    }
    
    // GLAD初期化（詳細エラー情報付き）
    if (!gladLoadGL(glfwGetProcAddress)) {
        // エラー詳細を取得
        spdlog::error("GLAD初期化失敗の詳細:");
        spdlog::error("  - GLコンテキスト: {}", glfwGetCurrentContext() ? "有効" : "無効");
        
        // OpenGL基本情報を直接取得試行
        auto glGetStringPtr = (const char* (*)(GLenum))glfwGetProcAddress("glGetString");
        if (glGetStringPtr) {
            const char* version = glGetStringPtr(0x1F02); // GL_VERSION
            spdlog::error("  - 検出されたOpenGLバージョン: {}", version ? version : "取得失敗");
        } else {
            spdlog::error("  - glGetString関数の取得に失敗");
        }
        
        throw WindowException("OpenGL関数ローダー(GLAD)の初期化に失敗 - グラフィックドライバーまたはOpenGL対応を確認してください");
    }
    
    const char* version = (const char*)glGetString(GL_VERSION);
    const char* renderer = (const char*)glGetString(GL_RENDERER);
    const char* vendor = (const char*)glGetString(GL_VENDOR);
    
    spdlog::info("OpenGL バージョン: {}", version ? version : "不明");
    spdlog::info("OpenGL レンダラー: {}", renderer ? renderer : "不明");
    spdlog::info("OpenGL ベンダー: {}", vendor ? vendor : "不明");
    
    // 深度テストを有効化
    glEnable(GL_DEPTH_TEST);
    
    // ビューポートを設定
    int fbWidth, fbHeight;
    glfwGetFramebufferSize(m_window, &fbWidth, &fbHeight);
    glViewport(0, 0, fbWidth, fbHeight);
    
    spdlog::info("OpenGL初期化完了");
}

void Window::SetupCallbacks() {
    glfwSetWindowUserPointer(m_window, this);
    glfwSetFramebufferSizeCallback(m_window, FramebufferSizeCallback);
    
    spdlog::info("GLFWコールバック設定完了");
}

void Window::ErrorCallback(int error, const char* description) {
    std::string error_type;
    switch (error) {
        case GLFW_NOT_INITIALIZED: error_type = "GLFW未初期化"; break;
        case GLFW_NO_CURRENT_CONTEXT: error_type = "GLコンテキスト無効"; break;
        case GLFW_INVALID_ENUM: error_type = "不正な列挙値"; break;
        case GLFW_INVALID_VALUE: error_type = "不正な値"; break;
        case GLFW_OUT_OF_MEMORY: error_type = "メモリ不足"; break;
        case GLFW_API_UNAVAILABLE: error_type = "API利用不可"; break;
        case GLFW_VERSION_UNAVAILABLE: error_type = "バージョン利用不可"; break;
        case GLFW_PLATFORM_ERROR: error_type = "プラットフォームエラー"; break;
        case GLFW_FORMAT_UNAVAILABLE: error_type = "フォーマット利用不可"; break;
        default: error_type = "不明なエラー"; break;
    }
    
    spdlog::error("GLFWエラー {} ({}): {}", error, error_type, description ? description : "詳細不明");
    
    // OpenGL関連エラーの場合は追加情報を提供
    if (error == GLFW_VERSION_UNAVAILABLE || error == GLFW_API_UNAVAILABLE) {
        spdlog::error("OpenGL 4.1 Core Profileがサポートされていない可能性があります");
        spdlog::error("グラフィックドライバーの更新またはより低いOpenGLバージョンの使用を検討してください");
    }
}

void Window::FramebufferSizeCallback(GLFWwindow* window, int width, int height) {
    glViewport(0, 0, width, height);
    
    auto* windowObj = static_cast<Window*>(glfwGetWindowUserPointer(window));
    if (windowObj) {
        windowObj->m_width = width;
        windowObj->m_height = height;
        spdlog::debug("フレームバッファサイズ変更: {}x{}", width, height);
    }
}

} // namespace BoxelGame