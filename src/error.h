// ----------------------------------------------------------------------------
// error.h: this file contains functions to get GL errors 
//
// Creation : Feb. 23th 2013
//
// Author: 2013-2014 Liming Xu 
//
// ----------------------------------------------------------------------------



#pragma once
#include "graphics.h"
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

namespace error
{
    bool checkFramebufferStatus();

    // print out the FBO infos
    void printFramebufferInfo();

    std::string convertInternalFormatToString(GLenum format);

    // return texture parameters as string using glGetTexLevelParameteriv()
    std::string getTextureParameters(GLuint id);

    // return renderbuffer parameters as string using glGetRenderbufferParameteriv
    std::string getRenderbufferParameters(GLuint id);
}

