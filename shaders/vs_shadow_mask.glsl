
uniform vec3 camera_pos;
uniform vec3 camera_dir;
uniform float depth_near;
uniform float depth_far;
varying float camera_depth;
varying vec4 tex_coord;

void main()
{
    tex_coord = gl_TextureMatrix[7] * gl_Vertex;
    vec3 offset  = (gl_Vertex.xyz / gl_Vertex.w) - camera_pos;
    float z      = dot(offset, normalize(camera_dir));
    camera_depth = (z-depth_near)/(depth_far - depth_near);
    gl_Position  = ftransform();

    /*
     *vec4 vert    = gl_ModelViewMatrix * gl_Vertex;
     *vec3 offset  = (vert.xyz / vert.w);
     *float z      = dot(offset, normalize(camera_dir));
     *camera_depth = (z-depth_near)/(depth_far - depth_near);
     *gl_Position = ftransform();
     */
}
