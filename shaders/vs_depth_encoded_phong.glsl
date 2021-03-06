

varying vec4 tex_coord_shadow;
varying vec3 light0_dir, light1_dir, light2_dir, light3_dir, eye_vec;
varying vec3 normal;

varying float keyfiber;
// if vertex color equals to keycolor, we don't apply any effect for tone shading
const vec4 keycolor = vec4(1.f, 1.f, 0.f, 1.f);

void main()
{
    tex_coord_shadow = gl_TextureMatrix[6] * gl_Vertex;

    normal = gl_NormalMatrix * gl_Normal;
    vec3 v_vertex = vec3( gl_ModelViewMatrix * gl_Vertex );
    light0_dir = vec3( gl_LightSource[0].position.xyz - v_vertex );
    light1_dir = vec3( gl_LightSource[1].position.xyz - v_vertex );
    light2_dir = vec3( gl_LightSource[2].position.xyz - v_vertex );
    light3_dir = vec3( gl_LightSource[3].position.xyz - v_vertex );
    eye_vec = -v_vertex;
    gl_Position = ftransform();

    // because of using the colorpointer
    // we use the glcolor as material diffuse
    gl_FrontColor = gl_Color;

    if(gl_Color == keycolor)
        keyfiber = 1.0f;
    else keyfiber = 0.f;

}
