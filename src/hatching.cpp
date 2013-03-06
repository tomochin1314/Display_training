#include "hatching.h"
#include "situbeRender.h"

void hatching_t::init_shader()
{
    depth_shader       = new shader_t("shaders/vs_depth.glsl", "shaders/ps_depth.glsl");
    shadow_mask_shader = new shader_t("shaders/vs_shadow_mask.glsl", "shaders/ps_shadow_mask.glsl");
    dbs_hatching_shader= new shader_t("shaders/vs_depth_encoded_hatching.glsl",
                                      "shaders/ps_depth_encoded_hatching.glsl");
    hatching_shader    = new shader_t("shaders/vs_hatching.glsl", "shaders/ps_hatching.glsl");

    halo_shader    = new shader_t("shaders/vs_halo.glsl", "shaders/ps_halo.glsl");

    if(depth_based_shadow)
        p_hatching_shader = dbs_hatching_shader;
    else p_hatching_shader = hatching_shader;

    //shadow_mask_tex_uniform = p_hatching_shader->get_uniform_location("shadow_mask");
    hatch_tex_uniform[0]       = p_hatching_shader->get_uniform_location("hatch0");
    hatch_tex_uniform[1]       = p_hatching_shader->get_uniform_location("hatch1");
    hatch_tex_uniform[2]       = p_hatching_shader->get_uniform_location("hatch2");
    hatch_tex_uniform[3]       = p_hatching_shader->get_uniform_location("hatch3");
    hatch_tex_uniform[4]       = p_hatching_shader->get_uniform_location("hatch4");
    hatch_tex_uniform[5]       = p_hatching_shader->get_uniform_location("hatch5");

    threshold_uniform0         = shadow_mask_shader->get_uniform_location("threshold0");
    reloc_scale_uniform0       = shadow_mask_shader->get_uniform_location("reloc_scale0");

    depth_tex_reloc_uniform[0] = shadow_mask_shader->get_uniform_location("depth_map0");
    depth_tex_reloc_uniform[1] = shadow_mask_shader->get_uniform_location("depth_map1");
    depth_tex_reloc_uniform[2] = shadow_mask_shader->get_uniform_location("depth_map2");
    depth_tex_reloc_uniform[3] = shadow_mask_shader->get_uniform_location("depth_map3");
}

void hatching_t::gen_reloc_depth_tex(GLuint w, GLuint h)
{
    for(GLuint i = 0; i < RELOC_NUM; ++i)
    {
        // Try to use a texture depth component
        glGenTextures(1, &depth_tex_reloc_id[i]);
        glBindTexture(GL_TEXTURE_2D, depth_tex_reloc_id[i]);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        // Remove artefact on the edges of the shadowmap
        glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        if(use_color_tex)
            glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA16, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        else
            glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, w, h, 0, 
                          GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, 0);
        glBindTexture(GL_TEXTURE_2D, 0);

    }
}


void hatching_t::generateShadowFBO()
{
    depth_map_width  = tr->m_width * SHADOW_MAP_RATIO;
    depth_map_height = tr->m_height * SHADOW_MAP_RATIO;


    gen_reloc_depth_tex(depth_map_width, depth_map_height);

    // Try to use a texture depth component
    glGenTextures(1, &shadow_mask_tex_id);
    glBindTexture(GL_TEXTURE_2D, shadow_mask_tex_id);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    if(use_color_tex)
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA16, depth_map_width, depth_map_height, 0, 
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

    glGenFramebuffersEXT(1, &fbo_id);
    glBindFramebufferEXT(GL_FRAMEBUFFER, fbo_id);

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
    //error::checkFramebufferStatus();
    //error::printFramebufferInfo();

    // switch back to window-system-provided framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void hatching_t::setupMatrices(float position_x,float position_y,float position_z,
        float lookAt_x,float lookAt_y,float lookAt_z)
{
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(tr->m_fvoy, tr->m_width/tr->m_height, tr->m_near, tr->m_far);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    gluLookAt(position_x,position_y,position_z,lookAt_x,lookAt_y,lookAt_z,0,1,0);
}


void hatching_t::setTextureMatrix(GLuint tex_unit_id)
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

// During translation, we also have to maintain the GL_TEXTURE8, used in the shadow shader
// to determine if a vertex is in the shadow.
void hatching_t::startTranslate(float x,float y,float z)
{
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glTranslatef(x,y,z);
	
	glMatrixMode(GL_TEXTURE);
	glActiveTextureARB(GL_TEXTURE7);
	glPushMatrix();
	glTranslatef(x,y,z);

    glMatrixMode(GL_MODELVIEW);
}

void hatching_t::endTranslate()
{
    glMatrixMode(GL_TEXTURE);
	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
}


//
// the first pass
//
void hatching_t::render_reloc_tube_depth(float scale, GLuint depth_tex_id)
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
        glDrawBuffer(GL_COLOR_ATTACHMENT0);
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
    //print_error();    
}


//
// the second pass
//
void hatching_t::render_shadow_mask_tex()
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

    //print_error();    
}

//
//  the third pass
//
void hatching_t::render_hatching()
{
    glPushAttrib(GL_ALL_ATTRIB_BITS);

    glEnable(GL_MULTISAMPLE);

    for(GLuint i = 0; i < lights.size(); ++i)
        lights[i].on();

    //Using the shadow shader
    p_hatching_shader->on();

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
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);


    if(depth_based_shadow)
    {
        glActiveTextureARB(GL_TEXTURE6);
        glBindTexture(GL_TEXTURE_2D,shadow_mask_tex_id);
        p_hatching_shader->set_uniform1i("shadow_mask", 6);
    }


    for(GLuint i = 0; i < 6; ++i)
    {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D,hatch_tex[i]);
        glUniform1iARB(hatch_tex_uniform[i],i);
    }

    tr->draw_tubes();

    p_hatching_shader->off();

    // draw the caps of tube separately
    hatching_shader->on();
    tr->draw_tube_caps();
    hatching_shader->off();

    for(GLuint i = 0; i < lights.size(); ++i)
        lights[i].off();

    glPopAttrib();
    //print_error();    
}

void hatching_t::render_halo()
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
void hatching_t::render_tex(GLuint tex_id)
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

void hatching_t::render() 
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

    render_hatching();

    //render_tex(depth_tex_reloc_id[0]);
    //render_tex(hatch_tex[0]);
    //render_tex(shadow_mask_tex_id);

    if(halo)
        render_halo();

    glMatrixMode(GL_MODELVIEW);
}

void hatching_t::calc_camera()
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


/*
   Read a line
   */
int hatching_t::ReadLine(FILE *fptr,char *s,int lmax)
{
    int i=0,c;

    s[0] = '\0';
    while ((c = fgetc(fptr)) != '\n' && c != '\r') {
        if (c == EOF)
            return(0);
        s[i] = c;
        i++;
        s[i] = '\0';
        if (i >= lmax)
            break;
    }
    return(1);
}

/*
   Read a PPM texture file and return a pointer to the pixelmap
   and the size of the image.
   Always return a texture unless the memory allocation fails.
   Return random noise if the file reading fails.
   1. The transparency is related to te intensity of the pixel
   2. The alpha value is set to 255 (opaque) unless the "trans" argument
   is 't' then treat the colour "c" as fully tranparent, alpha = 0;
   */
BITMAP4 *hatching_t::read_ppm(const char *fname,GLfloat *c,int trans,int *w,int *h,int tmode)
{
    int r,g,b;
    int i;
    double intensity,dr,dg,db,deltac = 1.0 / 255;
    FILE *fptr;
    char aline[256];
    BITMAP4 *ptr;

    /* Allocate memory for the texture */
    *w = 256;
    *h = 256;
    if ((ptr = (BITMAP4 *)malloc((*w)*(*h)*sizeof(BITMAP4))) == NULL) {
        fprintf(stderr,"Failed to allocate memory for texture \"%s\"\n",fname);
        exit(-1);
    }

    /* Start off with a random texture, totally opaque */
	for (i=0;i<(*w)*(*h);i++) {
		ptr[i].r = rand() % 255;
		ptr[i].g = rand() % 255;
		ptr[i].b = rand() % 255;
		ptr[i].a = 255;
	}

	/* Try to open the texture file */
	if ((fptr = fopen(fname,"rb")) == NULL) {
		fprintf(stderr,"Failed to open texture file \"%s\"\n",fname);
		return(ptr);
	}

	/* Read the PPM header */
	for (i=0;i<3;i++) {
		if (!ReadLine(fptr,aline,250))
			break;
		if (aline[0] == '#')
			i--;
		if (i == 1)
			sscanf(aline,"%d %d",w,h);
	}

	/* Allocate memory for the texture */
	if ((ptr = (BITMAP4 *)realloc(ptr,(*w)*(*h)*sizeof(BITMAP4))) == NULL) {
		fprintf(stderr,"Failed to allocate memory for texture \"%s\"\n",fname);
		exit(-1);
	}

	/* Start off with a random texture, totally opaque */
	for (i=0;i<(*w)*(*h);i++) {
		ptr[i].r = rand() % 255;
		ptr[i].g = rand() % 255;
		ptr[i].b = rand() % 255;
		ptr[i].a = 255;
	}

	/* Actually read the texture */
	for (i=0;i<(*w)*(*h);i++) {
		if ((r = fgetc(fptr)) != EOF &&
				(g = fgetc(fptr)) != EOF &&
				(b = fgetc(fptr)) != EOF) {
			ptr[i].r = r;
			ptr[i].g = g;
			ptr[i].b = b;

			/* Deal with transparency flag */
			if (trans == 't') {
				if (tmode == 1) {
					intensity = sqrt((double)r*r+g*g+b*b) / sqrtf(3.f);
					ptr[i].a = intensity;
				} else {
					dr = r / 255.0 - c[1];
					dg = g / 255.0 - c[2];
					db = b / 255.0 - c[3];
					if (abs(dr) < deltac && abs(dg) < deltac && abs(db) < deltac)
						ptr[i].a = 0;
				}
			}
		} else {
			/* Encountered short texture file */
			break;
		}
	}

	fclose(fptr);
	return(ptr);
}


void hatching_t::write_ppm(const BITMAP4 *const map, const int w, const int h)
{
    FILE *f = fopen("image.ppm", "w");
    fprintf(f, "P3\n%d %d\n%d\n", w, h, 255);
    for(int i = 0; i < w*h; ++i)
    {
        fprintf(f, "%d %d %d ", map[i].r, map[i].g, map[i].b);
    }
}


void hatching_t::read_tonal_art_maps()
{
    for(GLuint i = 0; i < 6; ++i)
    {
        std::string path("pictures/hatch");
        std::string suffix;
        std::stringstream out;
        out<<i; out>>suffix;
        path += suffix+std::string(".ppm");
        /*
         *if(i==4)
         *    path = std::string("pictures/image.ppm");
         */

        GLfloat white[] = { 1.0, 1.0, 1.0, 1.0 };
        hatch_pic[i] = read_ppm(path.c_str(),white,'o',&twidth,&theight,2);
        glGenTextures(1,&hatch_tex[i]);
        glBindTexture(GL_TEXTURE_2D,hatch_tex[i]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        gluBuild2DMipmaps(GL_TEXTURE_2D,GL_RGBA,twidth,theight,GL_RGBA,GL_UNSIGNED_BYTE,hatch_pic[i]);
        glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}



void hatching_t::init_light()
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
    eye_light.set_ambient(  vector_t(0.0, 0.0, 0.0, 1.0) );
    eye_light.set_diffuse(  vector_t(0.45, 0.45, 0.45, 1.0) );
    eye_light.set_specular( vector_t(1.0, 1.0, 1.0, 1.0) );
    //eye_light.off();

    // set overhead light
    overhead = center;
    overhead.y += 0.5 * (tr->m_maxCoord[1] - tr->m_minCoord[1]);
    light_t overhead_light;
    overhead_light.moveTo(overhead);
    overhead_light.set_ambient(  vector_t(0.1, 0.1, 0.1, 1.0) );
    overhead_light.set_diffuse(  vector_t(0.1, 0.1, 0.1, 1.0) );
    overhead_light.set_specular( vector_t(1.0, 1.0, 1.0, 1.0) );
    //overhead_light.off();

    // set left top light
    lefttop = overhead;
    lefttop.x -= 0.5 * (tr->m_maxCoord[0] - tr->m_minCoord[0]);
    light_t lt_light;
    lt_light.moveTo(lefttop);
    lt_light.set_ambient(  vector_t(0.0, 0.0, 0.0, 1.0) );
    lt_light.set_diffuse(  vector_t(0.1, 0.1, 0.1, 1.0) );
    lt_light.set_specular( vector_t(1.0, 1.0, 1.0, 1.0) );
    //lt_light.off();

    // set right top light
    righttop = overhead;
    righttop.x += 0.5 * (tr->m_maxCoord[0] - tr->m_minCoord[0]);
    light_t rt_light;
    rt_light.moveTo(righttop);
    rt_light.set_ambient(  vector_t(0.0, 0.0, 0.0, 1.0) );
    rt_light.set_diffuse(  vector_t(0.1, 0.1, 0.1, 1.0) );
    rt_light.set_specular( vector_t(1.0, 1.0, 1.0, 1.0) );
    //rt_light.off();

    lights.push_back(eye_light);
    lights.push_back(overhead_light);
    lights.push_back(lt_light);
    lights.push_back(rt_light);


    glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);
}

void hatching_t::init_material()
{
    mat_diffuse[0] = mat_diffuse[1] = mat_diffuse[2] = 1.f;
    mat_diffuse[3] = 1.0f;

    mat_specular[0] = mat_specular[1] = mat_specular[2] = mat_specular[3] = 1.0f;

    mat_ambient[0] = mat_ambient[1] = mat_ambient[2] = 0.1f;
    mat_ambient[3] = 1.0f;

    shininess = 128.0f;
}

// the length of shadow is related with the distance between two tubes
// we use exponential relationship here
// the function is: dist = (maxdist + 1)^(slen/max_slen) - 1
// here we use slen+slen_step instead of slen
// inorder to  map to larger interval of dist
void hatching_t::calc_shadow_len_threshold(GLfloat shadow_len_step)
{
    float max_dist = tr->m_fbdRadius *2.f; 

    shadow_len_threshold.clear();
    for(int i = 0; i < RELOC_NUM; ++i)
    {
        GLfloat dist = pow( (max_dist + 1), (relocation_level[i]+shadow_len_step)/MAX_SHADOW_LEN) - 1;
        shadow_len_threshold.push_back(dist);
    }

    //for(GLuint i = 0; i < shadow_len_threshold.size(); ++i)
        //printf("distance between tube threshold:%f\n", shadow_len_threshold[i]);
}


void hatching_t::init_misc()
{
    GLfloat slen_step = (MAX_SHADOW_LEN - MIN_SHADOW_LEN) / RELOC_NUM;

    relocation_level.clear();

    GLfloat shadow_length = MIN_SHADOW_LEN;
    for(int i = 0; i < RELOC_NUM; ++i)
    {
        relocation_level.push_back(shadow_length);
        shadow_length += slen_step;
    }

    //for(GLuint i = 0; i < relocation_level.size(); ++i)
        //printf("shadow length levels:%f\n", relocation_level[i]);
    calc_shadow_len_threshold(slen_step);
}

void hatching_t::init_hatching()
{
    use_color_tex = true;
    //use_color_tex = false;
    generateShadowFBO();
    init_shader();
    read_tonal_art_maps();
    init_misc();
    init_light();
    init_material();
}

void hatching_t::print_error()
{
    GLenum error = glGetError();
    printf("error code: %d, %x\n", error, error);
}

