
varying float camera_depth;

void main()
{
    /*gl_FragColor = vec4(camera_depth,0.,0.,1.);*/
    gl_FragDepth = camera_depth;
    /*gl_FragDepth = gl_FragCoord.z / 10.f;*/
}
