
varying float camera_depth;
varying vec3 normal;

void main()
{
    gl_FragColor = vec4(normalize(normal), camera_depth);
}
