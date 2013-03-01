/*************************************************************************
  > File Name: shader.cpp
  > Author: Liming Xu
  > Mail: Liming72217@gmail.com 
  > Created Time: 2013年01月29日 星期二 02时06分17秒
 ************************************************************************/

#include "shader.h"

// Loading shader function
GLhandleARB shader_t::loadShader(const char *const filename, unsigned int type)
{
    FILE *pfile;
    GLhandleARB handle;
    const GLcharARB* files[1];

    // shader Compilation variable
    GLint result;				// Compilation code result
    GLint errorLoglength ;
    char* errorLogText;
    GLsizei actualErrorLogLength;

    char buffer[400000];
    memset(buffer,0,400000);

    // This will raise a warning on MS compiler
    pfile = fopen(filename, "rb");
    if(!pfile)
    {
        printf("Sorry, can't open file: '%s'.\n", filename);
        exit(0);
    }

    fread(buffer,sizeof(char),400000,pfile);
    //printf("%s\n",buffer);


    fclose(pfile);

    handle = glCreateShaderObjectARB(type);
    if (!handle)
    {
        //We have failed creating the vertex shader object.
        printf("Failed creating vertex shader object from file: %s.",filename);
        exit(0);
    }

    files[0] = (const GLcharARB*)buffer;
    glShaderSourceARB(
            handle, //The handle to our shader
            1, //The number of files.
            files, //An array of const char * data, which represents the source code of theshaders
            NULL);

    glCompileShaderARB(handle);

    //Compilation checking.
    glGetObjectParameterivARB(handle, GL_OBJECT_COMPILE_STATUS_ARB, &result);

    // If an error was detected.
    if (!result)
    {
        //We failed to compile.
        printf("Shader '%s' failed compilation.\n",filename);

        //Attempt to get the length of our error log.
        glGetObjectParameterivARB(handle, GL_OBJECT_INFO_LOG_LENGTH_ARB, &errorLoglength);

        //Create a buffer to read compilation error message
        errorLogText = (char *)malloc(sizeof(char) * errorLoglength);

        //Used to get the final length of the log.
        glGetInfoLogARB(handle, errorLoglength, &actualErrorLogLength, errorLogText);

        // Display errors.
        printf("%s\n",errorLogText);

        // Free the buffer malloced earlier
        free(errorLogText);
    }

    return handle;
}

void shader_t::load(const char *const vs_file, const char *const ps_file)
{
    GLhandleARB vs_h;
    GLhandleARB ps_h;

    vs_h     = loadShader(vs_file, GL_VERTEX_SHADER);
    ps_h     = loadShader(ps_file, GL_FRAGMENT_SHADER);
    shader_h = glCreateProgramObjectARB();
    glAttachObjectARB(shader_h, vs_h);
    glAttachObjectARB(shader_h, ps_h);
    glLinkProgramARB(shader_h);

}


void shader_t::set_uniform1f(const char *const name, float value)
{
    GLuint uniform = glGetUniformLocationARB(shader_h,name); 
    glUniform1fARB(uniform, value);
}
void shader_t::set_uniform2f(const char *const name, float value1, float value2)
{
    GLuint uniform = glGetUniformLocationARB(shader_h,name); 
    glUniform2fARB(uniform, value1, value2);
}
void shader_t::set_uniform3f(const char *const name, float value1, float value2, float value3)
{
    GLuint uniform = glGetUniformLocationARB(shader_h,name); 
    glUniform3fARB(uniform, value1, value2, value3);
}
void shader_t::set_uniform4f(const char *const name, float value1, float value2, float value3, float value4)
{
    GLuint uniform = glGetUniformLocationARB(shader_h,name); 
    glUniform4fARB(uniform, value1, value2, value3, value4);
}

void shader_t::set_uniform1i(const char *const name, int value)
{
    GLuint uniform = glGetUniformLocationARB(shader_h,name); 
    glUniform1iARB(uniform, value);
}

GLuint shader_t::get_uniform_location(const char *const name)
{
    return glGetUniformLocationARB(shader_h, name);
}

void shader_t::on()
{
    glUseProgram(shader_h);
}

void shader_t::off()
{
    glUseProgram(0);
}


