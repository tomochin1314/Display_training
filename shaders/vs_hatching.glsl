
varying vec2 tex_coord_hatching;
varying vec3 light0_dir, light1_dir, light2_dir, light3_dir;
varying vec3 normal;

void main()
{
    tex_coord_hatching = vec2(gl_MultiTexCoord0);
    vec3 v_vertex   = vec3( gl_ModelViewMatrix * gl_Vertex );
    normal = normalize(gl_NormalMatrix * gl_Normal);

    light0_dir = normalize(vec3( gl_LightSource[0].position.xyz - v_vertex ));
    light1_dir = normalize(vec3( gl_LightSource[1].position.xyz - v_vertex ));
    light2_dir = normalize(vec3( gl_LightSource[2].position.xyz - v_vertex ));
    light3_dir = normalize(vec3( gl_LightSource[3].position.xyz - v_vertex ));

    gl_Position   = ftransform();
    gl_FrontColor = gl_Color;
}
