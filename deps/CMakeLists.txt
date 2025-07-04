message(STATUS "依存ライブラリのインストール開始")

# GLAD - OpenGL関数ローダー（ソースから作成）
add_library(glad STATIC 
    glad/src/gl.c
)

target_include_directories(glad PUBLIC 
    glad/include
)

# エイリアス作成
add_library(glad::glad ALIAS glad)

# プラットフォーム別のOpenGLライブラリリンク
if(WIN32)
    target_link_libraries(glad PUBLIC opengl32)
elseif(UNIX)
    find_package(OpenGL REQUIRED)
    target_link_libraries(glad PUBLIC OpenGL::GL)
endif()

# 警告を抑制
target_compile_options(glad PRIVATE -w)

# GLFW - プラットフォーム別設定
if(WIN32)
    CPMAddPackage(
        NAME glfw
        GITHUB_REPOSITORY glfw/glfw
        GIT_TAG 3.4
        OPTIONS
            "GLFW_BUILD_DOCS OFF"
            "GLFW_BUILD_EXAMPLES OFF"
            "GLFW_BUILD_TESTS OFF"
            "GLFW_INSTALL OFF"
            "GLFW_BUILD_WIN32 ON"
    )
else()
    CPMAddPackage(
        NAME glfw
        GITHUB_REPOSITORY glfw/glfw
        GIT_TAG 3.4
        OPTIONS
            "GLFW_BUILD_DOCS OFF"
            "GLFW_BUILD_EXAMPLES OFF"
            "GLFW_BUILD_TESTS OFF"
            "GLFW_INSTALL OFF"
            "GLFW_BUILD_WAYLAND_LIBDECOR ON"
            "GLFW_BUILD_WAYLAND ON"
            "GLFW_BUILD_X11 ON"
    )
endif()

# spdlog - ログライブラリ
CPMAddPackage(
    NAME spdlog
    GITHUB_REPOSITORY gabime/spdlog
    GIT_TAG v1.15.3
    OPTIONS
        "SPDLOG_BUILD_EXAMPLE OFF"
        "SPDLOG_BUILD_TESTS OFF"
)

# GLM - 数学ライブラリ
#CPMAddPackage(
#    NAME glm
#    GITHUB_REPOSITORY g-truc/glm
#    GIT_TAG 1.0.1
#)

# doctest - テストフレームワーク
CPMAddPackage(
    NAME doctest
    GITHUB_REPOSITORY doctest/doctest
    GIT_TAG v2.4.12
    OPTIONS
        "DOCTEST_WITH_TESTS OFF"
        "DOCTEST_WITH_MAIN_IN_STATIC_LIB OFF"
)

# EnTT - Entity Component System (フェーズ2で使用予定)
# CPMAddPackage(
#     NAME EnTT
#     GITHUB_REPOSITORY skypjack/entt
#     GIT_TAG v3.15.0
#     OPTIONS
#         "ENTT_BUILD_TESTING OFF"
#         "ENTT_BUILD_DOCS OFF"
#         "ENTT_BUILD_EXAMPLE OFF"
# )


# 警告を抑制
if(glfw_ADDED)
    set_target_properties(glfw PROPERTIES COMPILE_FLAGS "-w")
endif()

message(STATUS "依存ライブラリのインストール完了")