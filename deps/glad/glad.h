#ifndef GLAD_GL_H_
#define GLAD_GL_H_

#include <stddef.h>  // ptrdiff_t用

#ifdef __cplusplus
extern "C" {
#endif

// OpenGL基本型定義
typedef unsigned int GLenum;
typedef unsigned char GLboolean;
typedef unsigned int GLbitfield;
typedef void GLvoid;
typedef signed char GLbyte;
typedef short GLshort;
typedef int GLint;
typedef unsigned char GLubyte;
typedef unsigned short GLushort;
typedef unsigned int GLuint;
typedef int GLsizei;
typedef float GLfloat;
typedef float GLclampf;
typedef double GLdouble;
typedef double GLclampd;
typedef char GLchar;
typedef ptrdiff_t GLintptr;
typedef ptrdiff_t GLsizeiptr;

// OpenGL基本定数
#define GL_FALSE                          0
#define GL_TRUE                           1
#define GL_COLOR_BUFFER_BIT               0x00004000
#define GL_DEPTH_BUFFER_BIT               0x00000100
#define GL_DEPTH_TEST                     0x0B71
#define GL_VERSION                        0x1F02
#define GL_RENDERER                       0x1F01
#define GL_VENDOR                         0x1F00

// 関数ポインタ型定義
typedef void (*PFNGLCLEARCOLORPROC) (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
typedef void (*PFNGLCLEARPROC) (GLbitfield mask);
typedef void (*PFNGLVIEWPORTPROC) (GLint x, GLint y, GLsizei width, GLsizei height);
typedef void (*PFNGLENABLEPROC) (GLenum cap);
typedef const GLubyte* (*PFNGLGETSTRINGPROC) (GLenum name);

// 関数ポインタ（実行時に読み込み）
extern PFNGLCLEARCOLORPROC glClearColor;
extern PFNGLCLEARPROC glClear;
extern PFNGLVIEWPORTPROC glViewport;
extern PFNGLENABLEPROC glEnable;
extern PFNGLGETSTRINGPROC glGetString;

// GLAD初期化関数
int gladLoadGL(void);

#ifdef __cplusplus
}
#endif

#endif // GLAD_GL_H_