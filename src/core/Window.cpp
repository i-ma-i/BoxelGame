#include "core/Window.hpp"
#include <glad.h>       // GLADを先に読み込み
#define GLFW_INCLUDE_NONE // GLFWにOpenGLヘッダーを含めさせない
#include <GLFW/glfw3.h> // GLFWはGLADの後
#include <spdlog/spdlog.h>

namespace BoxelGame {

Window::Window(int width, int height, const std::string& title)
    : m_window(nullptr), m_width(width), m_height(height), m_title(title) {
    
    try {
        spdlog::info("ウィンドウ初期化開始: {}x{} \"{}\"", width, height, title);
        
        InitializeGLFW();
        CreateWindow();
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
    
    // OpenGL設定
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_ANY_PROFILE);
    spdlog::info("GLFW初期化完了");
    
    glfwWindowHint(GLFW_DOUBLEBUFFER, GLFW_TRUE);
    glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);
}

void Window::CreateWindow() {
    m_window = glfwCreateWindow(m_width, m_height, m_title.c_str(), nullptr, nullptr);
    if (!m_window) {
        throw WindowException("ウィンドウの作成に失敗");
    }
    
    glfwMakeContextCurrent(m_window);
    glfwSwapInterval(1); // VSync有効
    
    spdlog::info("ウィンドウ作成完了");
}

void Window::InitializeOpenGL() {
    if (!gladLoadGL()) {
        throw WindowException("OpenGLの初期化に失敗");
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
    spdlog::error("GLFWエラー {}: {}", error, description);
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