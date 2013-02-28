varying vec3 normal;

void main()
{
    vec4 s = vec4(1.f, 1.f, 1.f, 1.f);
    if(normal.x < 0.f) s.x = 0.f;
    if(normal.y < 0.f) s.y = 0.f;
    if(normal.z < 0.f) s.z = 0.f;

    gl_FragColor = s;
}
