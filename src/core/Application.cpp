#include "core/Application.hpp"
#include "core/Window.hpp"
#include <spdlog/spdlog.h>
#include <glad/gl.h>

namespace BoxelGame {

Application::Application() {
    try {
        InitializeLogging();
        InitializeWindow();
        
        spdlog::info("BoxelGame Application v1.0.0 初期化完了");
        
    } catch (const BoxelGameException&) {
        throw;
    } catch (const std::exception& e) {
        throw InitializationException("Application", e.what());
    } catch (...) {
        throw InitializationException("Application", "不明なエラー");
    }
}

Application::~Application() {
    spdlog::info("アプリケーション終了中...");
    m_window.reset();
    spdlog::info("アプリケーション終了完了");
}

void Application::Run() {
    spdlog::info("アプリケーション実行開始");
    
    MainLoop();
}

void Application::InitializeLogging() {
    try {
        spdlog::set_level(spdlog::level::info);
        spdlog::info("ログシステム初期化完了");
    } catch (const std::exception& e) {
        throw InitializationException("Logging", e.what());
    }
}

void Application::InitializeWindow() {
    try {
        spdlog::info("ウィンドウシステム初期化中...");
        m_window = std::make_unique<Window>(1280, 720, "BoxelGame - Voxel Sandbox");
        spdlog::info("ウィンドウシステム初期化完了");
    } catch (const std::exception& e) {
        throw InitializationException("Window", e.what());
    }
}

void Application::MainLoop() {
    spdlog::info("メインループ開始");
    
    while (!m_window->ShouldClose()) {
        m_window->PollEvents();
        
        Render();
        
        m_window->SwapBuffers();
    }
    
    spdlog::info("メインループ終了");
}

void Application::Render() {
    glClearColor(0.1f, 0.2f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

} // namespace BoxelGame