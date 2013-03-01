
uniform float scale;
uniform vec3 camera_pos;
uniform vec3 camera_dir;
uniform float depth_near;
uniform float depth_far;
varying float camera_depth;

void main()
{
    vec4 newpos  = gl_Vertex;
    newpos.xyz   = newpos.xyz + normalize(gl_Normal) * scale;
    
    vec3 offset  = (newpos.xyz / newpos.w) - camera_pos;
    float z      = dot(offset, normalize(camera_dir));
    camera_depth = (z-depth_near)/(depth_far - depth_near);

    gl_Position  = gl_ModelViewProjectionMatrix * newpos;
}
