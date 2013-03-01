
varying vec2 tex_coord_hatching;
varying vec3 light_dir;
varying vec3 hatch_weights0;
varying vec3 hatch_weights1;

void main()
{
    vec3 v_vertex   = vec3( gl_ModelViewMatrix * gl_Vertex );
    light_dir       = vec3( gl_LightSource[0].position.xyz - v_vertex );
    light_dir = normalize(light_dir);


    tex_coord_hatching = vec2(gl_MultiTexCoord0);

    /*vec3 posW    = gl_NormalMatrix * gl_Vertex.xyz;*/
    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);

    float  diffuse = min(1.0,max(0.0,dot(light_dir.xyz,normal)));
    diffuse = diffuse * diffuse;
    diffuse = diffuse * diffuse;
    /*diffuse = diffuse * diffuse;*/

    float  hatchFactor = diffuse * 6.0;
    vec3 weight0 = vec3(0.0);
    vec3 weight1 = vec3(0.0);

    if (hatchFactor>4.0)
    {
        weight0.x = 1.0;
    } // End if

    else if (hatchFactor>3.0)
    {
        weight0.x = 1.0 - (4.0 - hatchFactor);
        weight0.y = 1.0 - weight0.x;
    } // End else if

    else if (hatchFactor>2.0)
    {
        weight0.y = 1.0 - (3.0 - hatchFactor);
        weight0.z = 1.0 - weight0.y;
    } // End else if

    else if (hatchFactor>1.5)
    {
        weight0.z = 1.0 - (2.0 - hatchFactor);
        weight1.x = 1.0 - weight0.z;
    } // End else if

    else if (hatchFactor>1.0)
    {
        weight1.x = 1.0 - (1.5 - hatchFactor);
        weight1.y = 1.0 - weight1.x;
    } // End else if

    else if (hatchFactor>0.0)
    {
        weight1.y = 1.0 - (1.0 - hatchFactor);
        weight1.z = 1.0 - weight1.y;
    } // End else if

    hatch_weights0 = weight0;
    hatch_weights1 = weight1;

    gl_Position   = ftransform();
}
