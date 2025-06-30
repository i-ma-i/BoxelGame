#include "core/Application.hpp"
#include <spdlog/spdlog.h>

int main() {
    try {
        BoxelGame::Application app;
        app.Run();
        
    } catch (const BoxelGame::InitializationException& e) {
        spdlog::error("初期化エラー: {}", e.what());
        return -1;
    } catch (const BoxelGame::BoxelGameException& e) {
        spdlog::error("BoxelGameエラー: {}", e.what());
        return -1;
    } catch (const std::exception& e) {
        spdlog::error("未処理例外: {}", e.what());
        return -1;
    } catch (...) {
        spdlog::error("不明な例外が発生しました");
        return -1;
    }
    
    spdlog::info("正常終了");
    return 0;
}