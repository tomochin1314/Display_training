
uniform vec3 camera_pos;
uniform vec3 camera_dir;
uniform float depth_near;
uniform float depth_far;

varying float camera_depth;
varying vec3  normal;

void main()
{
    vec3 offset  = (gl_Vertex.xyz / gl_Vertex.w) - camera_pos;
    float z      = dot(offset, normalize(camera_dir));
    camera_depth = (z-depth_near)/(depth_far - depth_near);

    normal = normalize( (gl_ModelViewMatrix * vec4(gl_Normal.xyz, 0.f) ).xyz);

    gl_Position  = ftransform();

}
