#include "mocks/MockWindow.hpp"
#include <spdlog/spdlog.h>

namespace BoxelGame {

MockWindow::MockWindow(int width, int height, const std::string& title)
    : m_width(width), m_height(height), m_title(title),
      m_framebuffer_width(width), m_framebuffer_height(height) {
    spdlog::info("MockWindow作成: {}x{} \"{}\"", width, height, title);
}

bool MockWindow::ShouldClose() const {
    return m_should_close;
}

void MockWindow::SwapBuffers() {
    ++m_swap_buffers_calls;
    // モック実装：実際のバッファスワップは行わない
}

void MockWindow::PollEvents() {
    ++m_poll_events_calls;
    // モック実装：実際のイベント処理は行わない
}

void MockWindow::GetFramebufferSize(int& width, int& height) const {
    width = m_framebuffer_width;
    height = m_framebuffer_height;
}

} // namespace BoxelGame