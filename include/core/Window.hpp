#pragma once

// Windows.hのマクロ競合を回避
#ifdef WIN32
    #ifndef NOMINMAX
        #define NOMINMAX
    #endif
    #ifndef WIN32_LEAN_AND_MEAN
        #define WIN32_LEAN_AND_MEAN
    #endif
#endif

#include "core/Exception.hpp"
#include "core/IWindow.hpp"
#include <string>

struct GLFWwindow;

namespace BoxelGame {

// ウィンドウ関連の例外
class WindowException : public BoxelGameException {
public:
    explicit WindowException(const std::string& reason)
        : BoxelGameException("ウィンドウエラー: " + reason) {}
};

class Window : public IWindow {
public:
    Window(int width = 1920, int height = 1080, const std::string& title = "BoxelGame");
    ~Window();

    // コピー・ムーブ操作を削除（RAII/一意所有権）
    Window(const Window&) = delete;
    Window& operator=(const Window&) = delete;
    Window(Window&&) = delete;
    Window& operator=(Window&&) = delete;

    // IWindow インターフェース実装
    bool ShouldClose() const override;
    void SwapBuffers() override;
    void PollEvents() override;
    void GetFramebufferSize(int& width, int& height) const override;
    
    // IWindow インターフェース実装
    int GetWidth() const override { return m_width; }
    int GetHeight() const override { return m_height; }
    const std::string& GetTitle() const override { return m_title; }

private:
    GLFWwindow* m_window;
    int m_width;
    int m_height;
    std::string m_title;

    void InitializeGLFW();
    void InitializeWindow();
    void InitializeOpenGL();
    void SetupCallbacks();

    // GLFWコールバック関数
    static void ErrorCallback(int error, const char* description);
    static void FramebufferSizeCallback(GLFWwindow* window, int width, int height);
};

} // namespace BoxelGame