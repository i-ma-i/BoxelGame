#pragma once

#include <string>

namespace BoxelGame {

// Windowクラスのインターフェース
class IWindow {
public:
    virtual ~IWindow() = default;
    
    // ウィンドウ状態
    virtual bool ShouldClose() const = 0;
    
    // フレーム処理
    virtual void SwapBuffers() = 0;
    virtual void PollEvents() = 0;
    
    // ウィンドウ情報取得
    virtual void GetFramebufferSize(int& width, int& height) const = 0;
    
    // ウィンドウ基本情報
    virtual int GetWidth() const = 0;
    virtual int GetHeight() const = 0;
    virtual const std::string& GetTitle() const = 0;
};

} // namespace BoxelGame