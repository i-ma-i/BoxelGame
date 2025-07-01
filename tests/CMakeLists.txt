# シンプルなテスト設定

# テストファイルを自動収集
file(GLOB_RECURSE TEST_SOURCES "src/*.cpp")
file(GLOB_RECURSE MOCK_SOURCES "mocks/*.cpp")

# テストファイルを作成
add_executable(BoxelGameTests 
    test_main.cpp
    ${TEST_SOURCES}
    ${MOCK_SOURCES}
)

# メインライブラリをリンク
target_link_libraries(BoxelGameTests PRIVATE 
    BoxelGameLib
    doctest::doctest
)

# Windows特有の設定
if(WIN32)
    target_compile_definitions(BoxelGameTests PRIVATE
        _CRT_SECURE_NO_WARNINGS    # getenv等の警告を抑制
        NOMINMAX                   # min/maxマクロ競合回避
        WIN32_LEAN_AND_MEAN       # 不要なWindows API削減
    )
endif()

# テストディレクトリをインクルード
target_include_directories(BoxelGameTests PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)