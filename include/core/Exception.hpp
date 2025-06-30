#pragma once

#include <stdexcept>
#include <string>

namespace BoxelGame {

// BoxelGame共通の例外基底クラス
class BoxelGameException : public std::runtime_error {
public:
    explicit BoxelGameException(const std::string& message)
        : std::runtime_error(message) {}
};

// 初期化失敗時の例外
class InitializationException : public BoxelGameException {
public:
    explicit InitializationException(const std::string& component, const std::string& reason)
        : BoxelGameException("Failed to initialize " + component + ": " + reason) {}
};

// リソース関連のエラー例外
class ResourceException : public BoxelGameException {
public:
    explicit ResourceException(const std::string& resource, const std::string& reason)
        : BoxelGameException("Resource error '" + resource + "': " + reason) {}
};

} // namespace BoxelGame