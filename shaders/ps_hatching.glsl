uniform sampler2D hatch0;
uniform sampler2D hatch1;
uniform sampler2D hatch2;
uniform sampler2D hatch3;
uniform sampler2D hatch4;
uniform sampler2D hatch5;

varying vec3 light0_dir, light1_dir, light2_dir, light3_dir;
varying vec3 normal;

varying vec2 tex_coord_hatching;

// if gl_Color equals to keycolor, we don't apply any effect
const vec4 keycolor = vec4(1.f, 1.f, 0.f, 1.f);


float calc_diffuse_two_faces(vec3 nor)
{

    /*vec3 posW    = gl_NormalMatrix * gl_Vertex.xyz;*/
    float diffuse = min(1.0,max(0.0,dot(light0_dir.xyz,nor)));
    diffuse += min(1.0,max(0.0,dot(light1_dir.xyz,nor)));
    diffuse += min(1.0,max(0.0,dot(light2_dir.xyz,nor)));
    diffuse += min(1.0,max(0.0,dot(light3_dir.xyz,nor)));

    /*
     *diffuse *= diffuse;
     *diffuse *= diffuse;
     */
     diffuse *= 0.23;
    /*
     *diffuse *= diffuse;
     *diffuse *= diffuse;
     *diffuse *= diffuse;
     */

    return diffuse;
}

void calc_weight(float hatch_factor, out vec3 weight0, out vec3 weight1)
{
    weight0 = vec3(0.0);
    weight1 = vec3(0.0);

    if (hatch_factor>5.0)
    {
        weight0.x = 1.0;
    } // End if

    else if (hatch_factor>4.0)
    {
        weight0.x = 1.0 - (5.0 - hatch_factor);
        weight0.y = 1.0 - weight0.x;
    } // End else if

    else if (hatch_factor>3.0)
    {
        weight0.y = 1.0 - (4.0 - hatch_factor);
        weight0.z = 1.0 - weight0.y;
    } // End else if

    else if (hatch_factor>2.0)
    {
        weight0.z = 1.0 - (3.0 - hatch_factor);
        weight1.x = 1.0 - weight0.z;
    } // End else if

    else if (hatch_factor>1.0)
    {
        weight1.x = 1.0 - (2.0 - hatch_factor);
        weight1.y = 1.0 - weight1.x;
    } // End else if

    else if (hatch_factor>0.0)
    {
        weight1.y = 1.0 - (1.0 - hatch_factor);
        weight1.z = 1.0 - weight1.y;
    } // End else if
}



void main()
{

    vec3 weights0, weights1;

    float  hatchFactor= calc_diffuse_two_faces(normal) * 6.0;
    calc_weight(hatchFactor, weights0, weights1); 

    vec4 hatchColor;

    //
    // do the hatching
    //
   /*vec4 hatchTex0 = vec4(texture2D(hatch0,tex_coord_hatching).xyz * weights0.x, 1.0f);*/
    vec4 hatchTex0 = vec4(weights0.xxx, 1.f);
    vec4 hatchTex1 = vec4(texture2D(hatch1,tex_coord_hatching).xyz * weights0.y, 1.0f);
    vec4 hatchTex2 = vec4(texture2D(hatch3,tex_coord_hatching).xyz * weights0.z, 1.0f);
    vec4 hatchTex3 = vec4(texture2D(hatch3,tex_coord_hatching).xyz * weights1.x, 1.0f);
    vec4 hatchTex4 = vec4(texture2D(hatch5,tex_coord_hatching).xyz * weights1.y, 1.0f);
    vec4 hatchTex5 = vec4(texture2D(hatch5,tex_coord_hatching).xyz * weights1.z, 1.0f);

    hatchColor = hatchTex0 +
        hatchTex1 +
        hatchTex2 +
        hatchTex3 +
        hatchTex4 +
        hatchTex5;

    gl_FragColor = vec4(hatchColor * gl_Color.xyz, gl_Color.a);
    /*gl_FragColor = vec4(tex_coord_hatching.xy, 0.f, 1.0);;*/
    /*gl_FragColor = vec4(mask/10.f, 0.f, 0.f, 1.0f);*/
}


