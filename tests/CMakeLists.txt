# シンプルなテスト設定

# テストファイルを作成
add_executable(BoxelGameTests test_main.cpp)

# メインライブラリをリンク
target_link_libraries(BoxelGameTests PRIVATE 
    BoxelGameLib
    doctest::doctest
)

# テストディレクトリをインクルード
target_include_directories(BoxelGameTests PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src
)