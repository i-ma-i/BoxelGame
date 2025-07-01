#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include "core/Application.hpp"
#include "core/Exception.hpp"
#include "core/Window.hpp"
#include "mocks/MockWindow.hpp"
#include <spdlog/spdlog.h>
#include <cstdlib>

// CI環境チェック用ヘルパー関数
bool isCI() {
    const char* ci_env = std::getenv("CI");
    const char* github_actions = std::getenv("GITHUB_ACTIONS");
    return (ci_env && std::string(ci_env) == "true") || 
           (github_actions && std::string(github_actions) == "true");
}

// =============================================================================
// 論理テスト（CI環境でも実行）
// =============================================================================

TEST_CASE("1. 基本機能テスト") {
    CHECK(1 + 1 == 2);
    CHECK(2 * 3 == 6);
}

TEST_CASE("2. 例外階層テスト") {
    BoxelGame::InitializationException ex("TestComponent", "Test reason");
    const BoxelGame::BoxelGameException& base_ex = ex;
    CHECK(std::string(base_ex.what()).find("TestComponent") != std::string::npos);
    CHECK(std::string(base_ex.what()).find("Test reason") != std::string::npos);
}

TEST_CASE("3. ResourceExceptionテスト") {
    BoxelGame::ResourceException ex("TestResource", "Test reason");
    const BoxelGame::BoxelGameException& base_ex = ex;
    CHECK(std::string(base_ex.what()).find("TestResource") != std::string::npos);
    CHECK(std::string(base_ex.what()).find("Test reason") != std::string::npos);
}

TEST_CASE("4. 例外メッセージフォーマットテスト") {
    BoxelGame::InitializationException init_ex("Component", "reason");
    CHECK(std::string(init_ex.what()) == "Failed to initialize Component: reason");
    
    BoxelGame::ResourceException res_ex("Resource", "error");
    CHECK(std::string(res_ex.what()) == "Resource error 'Resource': error");
}

TEST_CASE("5. ログシステムテスト") {
    CHECK_NOTHROW({
        spdlog::set_level(spdlog::level::info);
        spdlog::info("テストメッセージ");
    });
}

TEST_CASE("6. 例外キャッチテスト") {
    try {
        throw BoxelGame::InitializationException("Test", "Error");
    } catch(const BoxelGame::BoxelGameException&) {
        CHECK(true);
    } catch(...) {
        CHECK(false);
    }
}

TEST_CASE("7. MockWindow論理テスト") {
    BoxelGame::MockWindow mock_window(800, 600, "Test Mock");
    
    // 基本属性テスト
    CHECK(mock_window.GetWidth() == 800);
    CHECK(mock_window.GetHeight() == 600);
    CHECK(mock_window.GetTitle() == "Test Mock");
    
    // 初期状態テスト
    CHECK_FALSE(mock_window.ShouldClose());
    CHECK(mock_window.GetSwapBuffersCallCount() == 0);
    CHECK(mock_window.GetPollEventsCallCount() == 0);
    
    // 動作テスト
    mock_window.SwapBuffers();
    mock_window.PollEvents();
    CHECK(mock_window.GetSwapBuffersCallCount() == 1);
    CHECK(mock_window.GetPollEventsCallCount() == 1);
    
    // 状態変更テスト
    mock_window.SetShouldClose(true);
    CHECK(mock_window.ShouldClose());
    
    // フレームバッファサイズテスト
    mock_window.SetFramebufferSize(1024, 768);
    int width, height;
    mock_window.GetFramebufferSize(width, height);
    CHECK(width == 1024);
    CHECK(height == 768);
}

TEST_CASE("8. MockWindowメモリ管理テスト") {
    auto mock_window = std::make_unique<BoxelGame::MockWindow>(640, 480, "Memory Test");
    CHECK_NOTHROW(mock_window->SwapBuffers());
    CHECK(mock_window->GetSwapBuffersCallCount() == 1);
    CHECK_NOTHROW(mock_window.reset());
}

// =============================================================================
// 統合テスト（ローカル環境のみ実行）
// =============================================================================

TEST_CASE("9. Application統合テスト") {
    if (isCI()) {
        return;
    }
    CHECK_NOTHROW({
        BoxelGame::Application app;
    });
}

TEST_CASE("10. Window統合テスト") {
    if (isCI()) {
        return;
    }
    
    BoxelGame::Window window(800, 600, "Integration Test");
    CHECK(window.GetWidth() == 800);
    CHECK(window.GetHeight() == 600);
    CHECK(window.GetTitle() == "Integration Test");
    
    int width, height;
    window.GetFramebufferSize(width, height);
    CHECK(width > 0);
    CHECK(height > 0);
}