# シンプルな依存関係設定（WSL環境対応）

message(STATUS "シンプルな依存関係設定を開始")

# GLAD - OpenGL関数ローダー（安定版v0.1.36使用）
CPMAddPackage(
    NAME glad
    GITHUB_REPOSITORY Dav1dde/glad
    GIT_TAG v0.1.36
    OPTIONS
        "GLAD_PROFILE core"
        "GLAD_API gl=4.6"
        "GLAD_GENERATOR c"
        "GLAD_SPEC gl"
        "GLAD_NO_LOADER OFF"
        "GLAD_REPRODUCIBLE ON"
)

# GLADが正常に追加された場合の設定
if(glad_ADDED)
    # プラットフォーム別のOpenGLライブラリリンク
    if(WIN32)
        target_link_libraries(glad PUBLIC opengl32)
    elseif(UNIX)
        find_package(OpenGL REQUIRED)
        target_link_libraries(glad PUBLIC OpenGL::GL)
    endif()
    
    # 警告を抑制
    target_compile_options(glad PRIVATE -w)
endif()

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
            "GLFW_BUILD_WAYLAND ON"
            "GLFW_BUILD_X11 OFF"
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
CPMAddPackage(
    NAME glm
    GITHUB_REPOSITORY g-truc/glm
    GIT_TAG 1.0.1
)

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

message(STATUS "シンプルな依存関係設定完了")