#include "glad.h"
#include <stddef.h>  // NULL用

#ifdef _WIN32
#include <windows.h>
#define gladGetProcAddress(name) ((void*)wglGetProcAddress(name))
#else
#include <dlfcn.h>
static void* libgl = NULL;
static void* gladGetProcAddress(const char* name) {
    if (!libgl) {
        libgl = dlopen("libGL.so.1", RTLD_LAZY | RTLD_GLOBAL);
        if (!libgl) {
            libgl = dlopen("libGL.so", RTLD_LAZY | RTLD_GLOBAL);
        }
    }
    if (libgl) {
        return dlsym(libgl, name);
    }
    return NULL;
}
#endif

// 関数ポインタ実体
PFNGLCLEARCOLORPROC glClearColor = NULL;
PFNGLCLEARPROC glClear = NULL;
PFNGLVIEWPORTPROC glViewport = NULL;
PFNGLENABLEPROC glEnable = NULL;
PFNGLGETSTRINGPROC glGetString = NULL;

// 関数ポインタ変換のヘルパー（警告回避）
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"

int gladLoadGL(void) {
    glClearColor = (PFNGLCLEARCOLORPROC)gladGetProcAddress("glClearColor");
    glClear = (PFNGLCLEARPROC)gladGetProcAddress("glClear");
    glViewport = (PFNGLVIEWPORTPROC)gladGetProcAddress("glViewport");
    glEnable = (PFNGLENABLEPROC)gladGetProcAddress("glEnable");
    glGetString = (PFNGLGETSTRINGPROC)gladGetProcAddress("glGetString");
    
    return (glClearColor && glClear && glViewport && glEnable && glGetString) ? 1 : 0;
}

#pragma GCC diagnostic pop