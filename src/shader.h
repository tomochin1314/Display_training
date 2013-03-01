/*************************************************************************
    > File Name: shader.h
    > Author: Liming Xu
    > Mail: Liming72217@gmail.com 
    > Created Time: 2013年01月29日 星期二 01时16分03秒
 ************************************************************************/
#pragma once
#include "graphics.h"
#include <stdio.h>
#include <stdlib.h>
#include <cstring>
#include <fstream>
#include <iostream>


class shader_t
{
    private:

        GLhandleARB shader_h;
        // Loading shader function
        GLhandleARB loadShader(const char *const filename, unsigned int type);



    public:
        shader_t(): shader_h(0){}
        shader_t(const char *const vs_file, const char *const ps_file)
        {
            load(vs_file, ps_file);
        }
        ~shader_t(){}

        void load(const char *const vs_file, const char *const ps_file);

        void on();
        void off();
        GLuint get_uniform_location(const char *const name);        
        void set_uniform1i(const char *const name, int value);
        void set_uniform1f(const char *const name, float value);
        void set_uniform2f(const char *const name, float value1, float value2);
        void set_uniform3f(const char *const name, float value1, float value2, float value3);
        void set_uniform4f(const char *const name, float value1, float value2, float value3, float value4);
};
