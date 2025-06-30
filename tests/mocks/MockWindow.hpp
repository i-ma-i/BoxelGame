#pragma once

#include "core/IWindow.hpp"

namespace BoxelGame {

// テスト用のモックWindowクラス
class MockWindow : public IWindow {
public:
    MockWindow(int width = 800, int height = 600, const std::string& title = "MockWindow");
    ~MockWindow() override = default;
    
    // IWindow インターフェース実装
    bool ShouldClose() const override;
    void SwapBuffers() override;
    void PollEvents() override;
    void GetFramebufferSize(int& width, int& height) const override;
    
    int GetWidth() const override { return m_width; }
    int GetHeight() const override { return m_height; }
    const std::string& GetTitle() const override { return m_title; }
    
    // テスト用メソッド
    void SetShouldClose(bool should_close) { m_should_close = should_close; }
    void SetFramebufferSize(int width, int height) { 
        m_framebuffer_width = width; 
        m_framebuffer_height = height; 
    }
    
    // 統計情報（テスト検証用）
    int GetSwapBuffersCallCount() const { return m_swap_buffers_calls; }
    int GetPollEventsCallCount() const { return m_poll_events_calls; }
    
private:
    int m_width;
    int m_height;
    std::string m_title;
    
    bool m_should_close = false;
    int m_framebuffer_width;
    int m_framebuffer_height;
    
    // 統計カウンタ
    mutable int m_swap_buffers_calls = 0;
    mutable int m_poll_events_calls = 0;
};

} // namespace BoxelGame