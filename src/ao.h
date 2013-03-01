// ----------------------------------------------------------------------------
// ao.h: ao shading class, this is a friend class of situbeRender
//
// Creation : Feb. 17th 2013
//
// Author: 2013-2014 Liming Xu 
//
// ----------------------------------------------------------------------------



#pragma once
#include "shader.h"
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <sstream>
#include <vector>
#include <string>
#include "point.h"
#include "Light.h"
#include "error.h"

class CSitubeRender;

#define SHADOW_MAP_RATIO 2 // shadow map size = SHADOW_MAP_RATIO * WINDOW_WIDTH, SHADOW_MAP_RATIO * WINDOW_HEIGHT
#define RELOC_NUM 3   // at most 8, number of relocation depth texture
#define RELOC_STEP 0.3
#define RELOC_INIT 0.5  // relocation scale, smallest value

#define TEXCOORD_V_STEP 0.2f  // used in situbeRender.cpp, generating the texcoord


typedef struct {
    unsigned char r,g,b,a;
} BITMAP4;


class ao_t
{
    protected:
        CSitubeRender *tr;
        std::vector<light_t> lights;
        bool halo;
        bool depth_based_shadow;
        GLfloat mat_diffuse[4];
        GLfloat mat_specular[4];
        GLfloat mat_ambient[4];
        GLfloat shininess;
        GLfloat look_at[3];
        GLfloat eye[3];
        GLfloat dir[3];
        bool use_color_tex;

        // Hold id of the framebuffer for light POV rendering
        GLuint fbo_id;
        GLuint rbo_id;
        GLuint pbo_id;
        GLuint pbo_data_size;

        bool use_fbo;

        GLuint depth_map_width;  // note the size of texture cannot be larger than window size in the non-fbo mode
        GLuint depth_map_height;

        // for shader 1---------------------------------------------------
        // render couple of depth textures
        shader_t *depth_shader;
        // depth_tex_reloc_id[RELOC_NUM-1] stores the largest relocation scale 
        GLuint depth_tex_reloc_id[RELOC_NUM];// these are color textures, we write the linear depth value into their red channels


        // for shader 2----------------------------------------------------
        // calculate the shadow mask texture using the results in shader 1
        shader_t *shadow_mask_shader;
        GLuint shadow_mask_depth_tex_id;  // depth texture
        GLuint shadow_mask_tex_id;  
        GLuint depth_tex_reloc_uniform[RELOC_NUM]; // result textures in shader 1 as inputs for shader 2
        GLuint threshold_uniform0, threshold_uniform1; // at most 8 thresholds, stored in two vec4
        std::vector<GLfloat> relocation_level;
        std::vector<GLfloat> shadow_len_threshold;
        GLuint reloc_scale_uniform0, reloc_scale_uniform1;

        // for shader 3---------------------------------------------------
        shader_t * dbs_ao_shader;  // for depth encoded shadow ao
        shader_t * ao_shader;   // for pure ao
        shader_t * p_ao_shader;  // just a pointer, decide which ao do we use
        shader_t *normalmap_shader;
        shader_t *normalmap_sign_shader;
        shader_t *combine_shader;    // this shader combines all effects together
        GLuint shadow_mask_tex_uniform; // the input
        GLuint normal_map_tex_id;
        GLuint rnm_tex_id;
        GLuint normal_map_sign_tex_id;
        GLuint ao_map_tex_id;

        /* Texture */
        int twidth,theight;
        BITMAP4 *rnm_pic;


    public:
        ao_t(CSitubeRender *_tr): halo(0), tr(_tr), depth_based_shadow(0){}
        ao_t(CSitubeRender *_tr, bool _halo, bool _shadow) : halo(_halo), tr(_tr),
                                                                   depth_based_shadow(_shadow){}
        ~ao_t()
        {
            if(depth_shader)
                delete depth_shader;
            if(shadow_mask_shader)
                delete shadow_mask_shader;
            if(ao_shader)
                delete ao_shader;
            if(dbs_ao_shader)
                delete dbs_ao_shader;
            if(rnm_pic)
                delete[] rnm_pic;
        }

        // the length of shadow is related with the distance between two tubes
        // we use exponential relationship here
        void calc_shadow_len_threshold();
        void init_misc();
        void gen_reloc_depth_tex(GLuint w, GLuint h);

        void generateShadowFBO();
        void setTextureMatrix(GLuint tex_unit_id);
        void calc_camera();
        //
        // the first pass
        //
        void render_reloc_tube_depth(float scale, GLuint depth_tex_id);
        //
        // the second pass
        //
        void render_shadow_mask_tex();
        //
        //  the third pass
        //
        void render_normalmap();
        void render_normalmap_sign();
        void render_ao_tex();
        void render_ao();

        void render_halo();
        // DEBUG only. this piece of code draw the depth buffer onscreen
        void render_tex(GLuint tex_id);
        void render() ;


        int ReadLine(FILE *fptr,char *s,int lmax);
        BITMAP4 *read_ppm(const char *fname,GLfloat *c,int trans,int *w,int *h,int tmode);
        void write_ppm(const BITMAP4 *const map, const int w, const int h); // for debug
        void read_tonal_art_maps();

        void init_ao();
        void init_shader();
        void init_light();
        void init_material();


        void set_halo(bool b) { halo = b; }
        void set_depth_based_shadow(bool b) { depth_based_shadow = b; }
        bool get_halo() const { return halo; }
        int get_num_light() const { return lights.size(); }
        void print_error();
};
