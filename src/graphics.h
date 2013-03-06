#ifndef mce_graphics
#define mce_graphics

//-------------------------------------------------------------
/* OpenGL libraries */
// Enable OpenGL extensions
#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/freeglut.h>
#include <GL/glext.h>


// #include "flags.h"
#ifdef DEBUG
#include <stdio.h>
#define ShowGLError { GLenum e = glGetError(); if ( e != GL_NO_ERROR ) fprintf( stderr, "%s on line %d of %s\n",  gluErrorString( e ), __LINE__, __FUNCTION__ ); }
#else
// exapnd to nothing for deployment builds
#define ShowGLError
#endif

//-------------------------------------------------------------

#endif
