#pragma once

#include "core/Exception.hpp"
#include <string>

struct GLFWwindow;

namespace BoxelGame {

// ウィンドウ関連の例外
class WindowException : public BoxelGameException {
public:
    explicit WindowException(const std::string& reason)
        : BoxelGameException("ウィンドウエラー: " + reason) {}
};

class Window {
public:
    Window(int width = 1920, int height = 1080, const std::string& title = "BoxelGame");
    ~Window();

    // コピー・ムーブ操作を削除（RAII/一意所有権）
    Window(const Window&) = delete;
    Window& operator=(const Window&) = delete;
    Window(Window&&) = delete;
    Window& operator=(Window&&) = delete;

    // ウィンドウ状態チェック
    bool ShouldClose() const;
    
    // フレーム処理
    void SwapBuffers();
    void PollEvents();
    
    // ウィンドウ情報取得
    void GetFramebufferSize(int& width, int& height) const;

private:
    GLFWwindow* m_window;
    int m_width;
    int m_height;
    std::string m_title;

    void InitializeGLFW();
    void CreateWindow();
    void InitializeOpenGL();
    void SetupCallbacks();

    // GLFWコールバック関数
    static void ErrorCallback(int error, const char* description);
    static void FramebufferSizeCallback(GLFWwindow* window, int width, int height);
};

} // namespace BoxelGame