#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include "core/Application.hpp"
#include "core/Exception.hpp"
#include "core/Window.hpp"
#include <spdlog/spdlog.h>

TEST_CASE("1. 基本機能テスト") {
    CHECK(1 + 1 == 2);
    CHECK(2 * 3 == 6);
}

TEST_CASE("2. Application RAIIテスト") {
    CHECK_NOTHROW({
        BoxelGame::Application app;
    });
}

TEST_CASE("3. InitializationExceptionテスト") {
    BoxelGame::InitializationException ex("TestComponent", "Test reason");
    const BoxelGame::BoxelGameException& base_ex = ex;
    CHECK(std::string(base_ex.what()).find("TestComponent") != std::string::npos);
    CHECK(std::string(base_ex.what()).find("Test reason") != std::string::npos);
}

TEST_CASE("4. ResourceExceptionテスト") {
    BoxelGame::ResourceException ex("TestResource", "Test reason");
    const BoxelGame::BoxelGameException& base_ex = ex;
    CHECK(std::string(base_ex.what()).find("TestResource") != std::string::npos);
    CHECK(std::string(base_ex.what()).find("Test reason") != std::string::npos);
}

TEST_CASE("5. Window作成テスト") {
    CHECK_NOTHROW({
        BoxelGame::Window window(800, 600, "Test Window");
    });
}

TEST_CASE("6. 例外メッセージフォーマットテスト") {
    BoxelGame::InitializationException init_ex("Component", "reason");
    CHECK(std::string(init_ex.what()) == "Failed to initialize Component: reason");
    
    BoxelGame::ResourceException res_ex("Resource", "error");
    CHECK(std::string(res_ex.what()) == "Resource error 'Resource': error");
}

TEST_CASE("7. ログシステムテスト") {
    CHECK_NOTHROW({
        spdlog::set_level(spdlog::level::info);
        spdlog::info("テストメッセージ");
    });
}

TEST_CASE("8. 例外階層テスト") {
    try {
        throw BoxelGame::InitializationException("Test", "Error");
    } catch(const BoxelGame::BoxelGameException& e) {
        CHECK(true);
    } catch(...) {
        CHECK(false);
    }
}

TEST_CASE("9. Windowサイズテスト") {
    BoxelGame::Window window(1024, 768, "Size Test");
    int width, height;
    window.GetFramebufferSize(width, height);
    CHECK(width > 0);
    CHECK(height > 0);
}

TEST_CASE("10. メモリ管理テスト") {
    CHECK_NOTHROW({
        auto window = std::make_unique<BoxelGame::Window>(640, 480, "Memory Test");
        window.reset();
    });
}