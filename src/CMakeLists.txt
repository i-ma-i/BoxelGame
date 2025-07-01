# BoxelGameコアライブラリ

# コアソースファイルを収集
set(BOXEL_SOURCES
    core/Application.cpp
    core/Window.cpp
)

# メインライブラリを作成
add_library(BoxelGameLib STATIC ${BOXEL_SOURCES})

# インクルードディレクトリ
target_include_directories(BoxelGameLib PUBLIC
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src
)

# 外部ライブラリをリンク
target_link_libraries(BoxelGameLib PUBLIC
    spdlog::spdlog
    glad::glad
    glfw
)

# コンパイラ固有の設定
target_compile_features(BoxelGameLib PUBLIC cxx_std_23)

if(MSVC)
    target_compile_options(BoxelGameLib PRIVATE /W4)
else()
    target_compile_options(BoxelGameLib PRIVATE -Wall -Wextra -Wpedantic)
endif()