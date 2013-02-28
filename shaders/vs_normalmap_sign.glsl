
varying vec3  normal;

void main()
{
    normal = normalize( (gl_ModelViewMatrix * vec4(gl_Normal.xyz, 0.f) ).xyz);
    gl_Position  = ftransform();
}
