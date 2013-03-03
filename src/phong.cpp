#include "phong.h"
#include "situbeRender.h"


void phong_t::init_shader()
{
    depth_shader       = new shader_t("shaders/vs_depth.glsl", "shaders/ps_depth.glsl");
    shadow_mask_shader = new shader_t("shaders/vs_shadow_mask.glsl", "shaders/ps_shadow_mask.glsl");
    dbs_phong_shader   = new shader_t("shaders/vs_depth_encoded_phong.glsl",
                                      "shaders/ps_depth_encoded_phong.glsl");
    phong_shader       = new shader_t("shaders/vs_phong.glsl", "shaders/ps_phong.glsl");

    halo_shader       = new shader_t("shaders/vs_halo.glsl", "shaders/ps_halo.glsl");

    if(depth_based_shadow)
        p_phong_shader  = dbs_phong_shader;
    else p_phong_shader = phong_shader;


    threshold_uniform0         = shadow_mask_shader->get_uniform_location("threshold0");
    reloc_scale_uniform0       = shadow_mask_shader->get_uniform_location("reloc_scale0");

    depth_tex_reloc_uniform[0] = shadow_mask_shader->get_uniform_location("depth_map0");
    depth_tex_reloc_uniform[1] = shadow_mask_shader->get_uniform_location("depth_map1");
    depth_tex_reloc_uniform[2] = shadow_mask_shader->get_uniform_location("depth_map2");
    depth_tex_reloc_uniform[3] = shadow_mask_shader->get_uniform_location("depth_map3");

}

void phong_t::gen_reloc_depth_tex(GLuint w, GLuint h)
{
    for(GLuint i = 0; i < RELOC_NUM; ++i)
    {
        // Try to use a texture depth component
        glGenTextures(1, &depth_tex_reloc_id[i]);
        glBindTexture(GL_TEXTURE_2D, depth_tex_reloc_id[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        // Remove artefact on the edges of the shadowmap
        glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        if(use_color_tex)
            glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        else
            glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, w, h, 0, 
                          GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, 0);
        glBindTexture(GL_TEXTURE_2D, 0);

    }
}


void phong_t::generateShadowFBO()
{
    depth_map_width  = tr->m_width * SHADOW_MAP_RATIO;
    depth_map_height = tr->m_height * SHADOW_MAP_RATIO;


    gen_reloc_depth_tex(depth_map_width, depth_map_height);

    // Try to use a texture depth component
    glGenTextures(1, &shadow_mask_tex_id);
    glBindTexture(GL_TEXTURE_2D, shadow_mask_tex_id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    if(use_color_tex)
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, depth_map_width, depth_map_height, 0, 
                      GL_RGBA, GL_UNSIGNED_BYTE, 0);
    else
        glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, depth_map_width, depth_map_height, 0, 
                      GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, 0);
    glBindTexture(GL_TEXTURE_2D, 0);


    if(use_color_tex)
    {
        // Try to use a texture depth component
        glGenTextures(1, &shadow_mask_depth_tex_id);
        glBindTexture(GL_TEXTURE_2D, shadow_mask_depth_tex_id);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, depth_map_width, depth_map_height, 0, 
                GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, 0);
        glBindTexture(GL_TEXTURE_2D, 0);
    }


    // create a framebuffer object
    glGenFramebuffers(1, &fbo_id);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo_id);
    glGenRenderbuffers(1, &rbo_id);
    glBindRenderbuffer(GL_RENDERBUFFER, rbo_id);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, depth_map_width, depth_map_height);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);

    
    // attach the texture to FBO depth attachment point
    if(use_color_tex)
    {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D, depth_tex_reloc_id[0], 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D, shadow_mask_depth_tex_id, 0);
    }
    else
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D, depth_tex_reloc_id[0], 0);



    // Instruct openGL that we won't bind a color texture with the currently binded FBO
    if(!use_color_tex)
    {
        glDrawBuffer(GL_NONE);
        glReadBuffer(GL_NONE);
    }
    else
        glDrawBuffer(GL_COLOR_ATTACHMENT0);

    // check FBO status
    error::checkFramebufferStatus();
    error::printFramebufferInfo();

    // switch back to window-system-provided framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void phong_t::setTextureMatrix(GLuint tex_unit_id)
{
    static double modelView[16];
    static double projection[16];

    // This is matrix transform every coordinate x,y,z
    // x = x* 0.5 + 0.5 
    // y = y* 0.5 + 0.5 
    // z = z* 0.5 + 0.5 
    // Moving from unit cube [-1,1] to [0,1]  
    const GLdouble bias[16] = {	
        0.5, 0.0, 0.0, 0.0, 
        0.0, 0.5, 0.0, 0.0,
        0.0, 0.0, 0.5, 0.0,
        0.5, 0.5, 0.5, 1.0};

    // Grab modelview and transformation matrices
    glGetDoublev(GL_MODELVIEW_MATRIX, modelView);
    glGetDoublev(GL_PROJECTION_MATRIX, projection);


    glMatrixMode(GL_TEXTURE);
    glActiveTextureARB(GL_TEXTURE0 + tex_unit_id);

    glLoadIdentity();	
    glLoadMatrixd(bias);

    // concatating all matrice into one.
    glMultMatrixd (projection);
    glMultMatrixd (modelView);

    glMatrixMode(GL_MODELVIEW);
}


//
// the first pass
//
void phong_t::render_reloc_tube_depth(float scale, GLuint depth_tex_id)
{
    // if not push all attrib here, 
    // just push enable bits and viewport bits, will be somehing wrong
    // I don't know why
    // TODO:figure out?
    glPushAttrib(GL_ALL_ATTRIB_BITS);
       
    depth_shader->on();

    depth_shader->set_uniform1f("scale", scale);
    depth_shader->set_uniform3f("camera_pos", eye[0], eye[1], eye[2]);
    depth_shader->set_uniform3f("camera_dir", dir[0], dir[1], dir[2]); 
    depth_shader->set_uniform1f("depth_far", tr->m_far);
    depth_shader->set_uniform1f("depth_near", tr->m_near);


    glBindFramebuffer(GL_FRAMEBUFFER,fbo_id);	//Rendering offscreen
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    if(use_color_tex)
    {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D, depth_tex_id, 0);
        //glDrawBuffer(GL_COLOR_ATTACHMENT0);
        glClearColor(0.0, 1.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);    
    }
    else
    {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D, depth_tex_id, 0);
        glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE); 
        glClearDepth(1.0f);
        glClear(GL_DEPTH_BUFFER_BIT);    
    }

    glViewport(0, 0, depth_map_width, depth_map_height);

    tr->draw_tubes();

    depth_shader->off();

    glBindFramebuffer(GL_FRAMEBUFFER,0);	
    glPopAttrib();
    print_error();    
}


//
// the second pass
//
void phong_t::render_shadow_mask_tex()
{
    // if not push all attrib here, 
    // just push enable bits and viewport bits, will be somehing wrong
    // I don't know why
    // TODO:figure out?
    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glEnable(GL_DEPTH_TEST);

    shadow_mask_shader->on();

    shadow_mask_shader->set_uniform3f("camera_pos", eye[0], eye[1], eye[2]);
    shadow_mask_shader->set_uniform3f("camera_dir", dir[0], dir[1], dir[2]);

    shadow_mask_shader->set_uniform1f("depth_far", tr->m_far);
    shadow_mask_shader->set_uniform1f("depth_near", tr->m_near);
    glUniform4fARB(reloc_scale_uniform0, relocation_level[0], relocation_level[1], relocation_level[2], 
                   relocation_level[3]);
    glUniform4fARB(threshold_uniform0, shadow_len_threshold[0], shadow_len_threshold[1], 
                   shadow_len_threshold[2], shadow_len_threshold[3]);


    glBindFramebuffer(GL_FRAMEBUFFER,fbo_id);	//Rendering offscreen

    if(use_color_tex)
    {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D, shadow_mask_tex_id, 0);
        //glDrawBuffer(GL_COLOR_ATTACHMENT0);
        glClearColor(0.0, 1.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);    
    }
    else
    {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D, shadow_mask_tex_id, 0);
        glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE); 
        glClear(GL_DEPTH_BUFFER_BIT);    
    }


    for(GLuint i = 0; i < RELOC_NUM; ++i)
    {
        glActiveTextureARB(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, depth_tex_reloc_id[i]);
        glUniform1iARB(depth_tex_reloc_uniform[i], i);
    }

    glViewport(0,0,depth_map_width, depth_map_height);

    // setup texture matrix
    setTextureMatrix(7);

    tr->draw_tubes();

    glBindFramebuffer(GL_FRAMEBUFFER,0);

    shadow_mask_shader->off();

    glPopAttrib();

    print_error();    
}

//
//  the third pass
//
void phong_t::render_phong()
{
    glPushAttrib(GL_ALL_ATTRIB_BITS);

    glShadeModel(GL_SMOOTH);
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    glEnable( GL_BLEND );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    glEnable( GL_POINT_SMOOTH);
    glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
    glEnable( GL_LINE_SMOOTH );
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
    glEnable( GL_POLYGON_SMOOTH);
    glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);


    for(GLuint i = 0; i < lights.size(); ++i)
        lights[i].on();

    //Using the shadow shader
    p_phong_shader->on();

    if(depth_based_shadow)
    {
        glViewport(0,0,depth_map_width, depth_map_height);
        setTextureMatrix(6);
    }

    // Now rendering from the camera POV, using the FBO to generate shadows
    glBindFramebuffer(GL_FRAMEBUFFER,0);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE); 
    glViewport(0,0, tr->m_width, tr->m_height);
    //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);


    if(depth_based_shadow)
    {
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        glActiveTextureARB(GL_TEXTURE6);
        glBindTexture(GL_TEXTURE_2D,shadow_mask_tex_id);
        p_phong_shader->set_uniform1i("shadow_mask", 6);
    }

    glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
	glMaterialf(GL_FRONT, GL_SHININESS, shininess );		
	//glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);

    tr->draw_tubes();

    p_phong_shader->off();

    for(GLuint i = 0; i < lights.size(); ++i)
        lights[i].off();

    glPopAttrib();
    print_error();    
}

void phong_t::render_halo()
{
    glPushAttrib(GL_ALL_ATTRIB_BITS);
    for(GLuint i = 0; i < lights.size(); ++i)
        lights[i].off();

    halo_shader->on();
    // draw outlines
    glPolygonMode(GL_BACK, GL_LINE);
    glDepthFunc(GL_LEQUAL);
    glCullFace(GL_FRONT);
    glLineWidth(2);
    glColor3f(0,0,0);

    tr->draw_tubes();
    halo_shader->off();
    glPopAttrib();

}

// DEBUG only. this piece of code draw the depth buffer onscreen
// Don't call glClear in this function
void phong_t::render_tex(GLuint tex_id)
{
    glPushAttrib(GL_ALL_ATTRIB_BITS);
	glPushClientAttrib(GL_ALL_CLIENT_ATTRIB_BITS);

	glDisableClientState( GL_VERTEX_ARRAY );
	glDisableClientState( GL_COLOR_ARRAY );
    glDisableClientState( GL_NORMAL_ARRAY );
    glDisableClientState( GL_TEXTURE_COORD_ARRAY );

    glUseProgramObjectARB(0);
    glBindFramebuffer(GL_FRAMEBUFFER,0);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE); 

    glDisable(GL_BLEND);
    glDisable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    
    glEnable(GL_TEXTURE_2D);
    glActiveTextureARB(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, tex_id);

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(-tr->m_width/2,tr->m_width/2,-tr->m_height/2,tr->m_height/2,1,20);

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    glTranslated(0,0,-1);


    glBegin(GL_QUADS);
    glTexCoord2d(0,0);glVertex3f(-tr->m_width/2,0,0);
    glTexCoord2d(1,0);glVertex3f(0,0,0);
    glTexCoord2d(1,1);glVertex3f(0,tr->m_height/2,0);
    glTexCoord2d(0,1);glVertex3f(-tr->m_width/2,tr->m_height/2,0);
    glEnd();

    glMatrixMode(GL_PROJECTION);
    glPopMatrix();

    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();

    glPopClientAttrib();
    glPopAttrib();
}

void phong_t::render() 
{
    calc_camera();

    // move the eye light to the eye position
    lights[0].moveTo(vector_t(eye[0], eye[1], eye[2]));

    if(depth_based_shadow)
    {
        for(int i = 0; i < RELOC_NUM; ++i)
        {
            render_reloc_tube_depth(relocation_level[i], depth_tex_reloc_id[i]);
        }
        render_shadow_mask_tex();
    }

    render_phong();

    //render_tex(depth_tex_reloc_id[0]);
    //render_tex(hatch_tex[0]);
    //render_tex(shadow_mask_tex_id);

    if(halo)
        render_halo();

    glMatrixMode(GL_MODELVIEW);
}

void phong_t::calc_camera()
{
    look_at[0] = ( tr->m_minCoord[0] + tr->m_maxCoord[0] ) * 0.5f; 
    look_at[1] = ( tr->m_minCoord[1] + tr->m_maxCoord[1] ) * 0.5f;
    look_at[2] = ( tr->m_minCoord[2] + tr->m_maxCoord[2] ) * 0.5f;

    //look_at[0] = look_at[1] = look_at[2] = 0.f;

    /*
     *look_at[0] = tr->m_centerX;
     *look_at[1] = tr->m_centerY;
     *look_at[2] = tr->m_centerZ;
     */

    // eye pos will not change in the three pass
    // and we assume there is no scaling
    // TODO: add support for scaling
    GLdouble mdl[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mdl);
    eye[0] = -( mdl[0] * mdl[12] + mdl[1] * mdl[13] + mdl[2] * mdl[14] );
    eye[1] = -( mdl[4] * mdl[12] + mdl[5] * mdl[13] + mdl[6] * mdl[14] );
    eye[2] = -( mdl[8] * mdl[12] + mdl[9] * mdl[13] + mdl[10] * mdl[14] );


    //eye[0] = tr->m_eyeX; eye[1] = tr->m_eyeY; eye[2] = tr->m_eyeZ;

    dir[0] = look_at[0] - eye[0];
    dir[1] = look_at[1] - eye[1];
    dir[2] = look_at[2] - eye[2];

    /*
     *tr->m_cout<<"eye pos:"<<eye[0]<<" "<<eye[1]<<" "<<eye[2]<<"\n";
     *tr->m_cout<<"look at:"<<look_at[0]<<" "<<look_at[1]<<" "<<look_at[2]<<"\n";
     */

}

//
// the setup of light color is put in shader file, which is shaders/ps_phong.glsl
void phong_t::init_light()
{
    lights.clear();

    vector_t eye, center, overhead, lefttop, righttop,
             maxcoord, mincoord;

    eye.x = tr->m_eyeX;
    eye.y = tr->m_eyeY;
    eye.z = tr->m_eyeZ;

    center.x = (tr->m_maxCoord[0] + tr->m_minCoord[0]) / 2.f;
    center.y = (tr->m_maxCoord[1] + tr->m_minCoord[1]) / 2.f;
    center.z = (tr->m_maxCoord[2] + tr->m_minCoord[2]) / 2.f;


    // set eye light
    light_t eye_light;
    eye_light.moveTo(eye);
    //eye_light.off();

    // set overhead light
    overhead = center;
    overhead.y += (tr->m_maxCoord[1] - tr->m_minCoord[1]);
    light_t overhead_light;
    overhead_light.moveTo(overhead);
    //overhead_light.off();

    // set left top light
    lefttop = overhead;
    lefttop.x -= (tr->m_maxCoord[0] - tr->m_minCoord[0]);
    lefttop.y += (tr->m_maxCoord[1] - tr->m_minCoord[1]);
    light_t lt_light;
    lt_light.moveTo(lefttop);
    //lt_light.off();

    // set right top light
    righttop = overhead;
    righttop.x += (tr->m_maxCoord[0] - tr->m_minCoord[0]);
    righttop.y += (tr->m_maxCoord[1] - tr->m_minCoord[1]);
    light_t rt_light;
    rt_light.moveTo(righttop);
    //rt_light.off();

    lights.push_back(eye_light);
    lights.push_back(overhead_light);
    lights.push_back(lt_light);
    lights.push_back(rt_light);
}

// do not set diffuse material, because we used glcolormaterial
void phong_t::init_material()
{
    mat_specular[0] = mat_specular[1] = mat_specular[2] = mat_specular[3] = 1.0f;

    mat_ambient[0] = mat_ambient[1] = mat_ambient[2] = 0.2f;
    mat_ambient[3] = 1.0f;

    shininess = 64.0f;
}


// the length of shadow is related with the distance between two tubes
// we use exponential relationship here
// the function is: dist = (maxdist + 1)^(slen/max_slen) - 1
// here we use slen+slen_step instead of slen
// inorder to  map to larger interval of dist
void phong_t::calc_shadow_len_threshold(GLfloat shadow_len_step)
{
    float max_dist = tr->m_fbdRadius *2.f; 

    shadow_len_threshold.clear();
    for(int i = 0; i < RELOC_NUM; ++i)
    {
        GLfloat dist = pow( (max_dist + 1), (relocation_level[i]+shadow_len_step)/MAX_SHADOW_LEN) - 1;
        shadow_len_threshold.push_back(dist);
    }

    for(GLuint i = 0; i < shadow_len_threshold.size(); ++i)
        printf("distance between tube threshold:%f\n", shadow_len_threshold[i]);
}


void phong_t::init_misc()
{
    GLfloat slen_step = (MAX_SHADOW_LEN - MIN_SHADOW_LEN) / RELOC_NUM;

    relocation_level.clear();

    GLfloat shadow_length = MIN_SHADOW_LEN;
    for(int i = 0; i < RELOC_NUM; ++i)
    {
        relocation_level.push_back(shadow_length);
        shadow_length += slen_step;
    }

    for(GLuint i = 0; i < relocation_level.size(); ++i)
        printf("shadow length levels:%f\n", relocation_level[i]);
    calc_shadow_len_threshold(slen_step);
}

void phong_t::init_phong()
{
    //use_color_tex = true;
    use_color_tex = false;
    if(depth_based_shadow)
        generateShadowFBO();

    init_shader();
    init_misc();
    init_light();
    init_material();
}

void phong_t::print_error()
{
    GLenum error = glGetError();
    printf("error code: %d, %x\n", error, error);
}

