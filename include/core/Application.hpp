#pragma once

#include "core/Exception.hpp"
#include <memory>

namespace BoxelGame {

class Window;

class Application {
public:
    Application();
    ~Application();

    // コピー・ムーブ操作を削除（RAII/一意所有権）
    Application(const Application&) = delete;
    Application& operator=(const Application&) = delete;
    Application(Application&&) = delete;
    Application& operator=(Application&&) = delete;

    void Run();

private:
    std::unique_ptr<Window> m_window;
    
    void InitializeLogging();
    void InitializeWindow();
    void MainLoop();
    void Render();
};

} // namespace BoxelGame