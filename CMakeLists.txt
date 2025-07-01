cmake_minimum_required(VERSION 3.19)

# プロジェクト名とバージョンを設定
project(BoxelGame VERSION 1.0.0 LANGUAGES C CXX)

# C++23標準を設定
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# テストを有効化
enable_testing()

# パッケージ管理用CPM.cmake
include(cmake/CPM.cmake)

# コンパイラ固有のフラグ
if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

# Debug/Release設定
set(CMAKE_CONFIGURATION_TYPES "Debug;Release;RelWithDebInfo;MinSizeRel" CACHE STRING "" FORCE)


# サブディレクトリを追加
add_subdirectory(extern)
add_subdirectory(src)
add_subdirectory(tests)

# 実行ファイルを定義
add_executable(${PROJECT_NAME} src/main.cpp)

# ライブラリをリンク（src/CMakeLists.txtで定義）
target_link_libraries(${PROJECT_NAME} PRIVATE BoxelGameLib)

# 出力ディレクトリを設定
set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

# アセットを出力ディレクトリにコピー（存在する場合のみ）
if(EXISTS ${CMAKE_SOURCE_DIR}/assets)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_SOURCE_DIR}/assets $<TARGET_FILE_DIR:${PROJECT_NAME}>/assets
    )
    message(STATUS "Assets directory found - will be copied to output directory")
else()
    message(STATUS "Assets directory not found - skipping asset copy")
endif()