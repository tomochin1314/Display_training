uniform sampler2D shadow_mask;
uniform sampler2D hatch0;
uniform sampler2D hatch1;
uniform sampler2D hatch2;
uniform sampler2D hatch3;
uniform sampler2D hatch4;
uniform sampler2D hatch5;

varying vec4 tex_coord_shadow;
varying vec2 tex_coord_hatching;

varying vec3 hatch_weights0;
varying vec3 hatch_weights1;

void main()
{	
	vec4 shadowCoordinateWdivide = tex_coord_shadow / tex_coord_shadow.w ;
    /*shadowCoordinateWdivide.z += 0.0005;*/
    float mask = texture2D(shadow_mask,  shadowCoordinateWdivide.st).x;


    vec4 hatchColor;
    if (mask > 0.f)
    {
        hatchColor = texture2D(hatch5, tex_coord_hatching);
    }
    else
    {
        //
        // do the hatching
        //
        /*vec4 hatchTex0 = texture2D(hatch0,tex_coord_hatching) * hatch_weights0.x;*/
        vec4 hatchTex0 = vec4(1.f, 1.f, 1.f, 1.f) * hatch_weights0.x;
        vec4 hatchTex1 = texture2D(hatch1,tex_coord_hatching) * hatch_weights0.y;
        vec4 hatchTex2 = texture2D(hatch2,tex_coord_hatching) * hatch_weights0.z;
        vec4 hatchTex3 = texture2D(hatch3,tex_coord_hatching) * hatch_weights1.x;
        vec4 hatchTex4 = texture2D(hatch4,tex_coord_hatching) * hatch_weights1.y;
        vec4 hatchTex5 = texture2D(hatch5,tex_coord_hatching) * hatch_weights1.z;

        hatchColor = hatchTex0 +
            hatchTex1 +
            hatchTex2 +
            hatchTex3 +
            hatchTex4 +
            hatchTex5;

    }
    gl_FragColor = hatchColor;
    /*gl_FragColor = vec4(mask, mask, mask, 1.0f);*/
    /*gl_FragColor = vec4(delta*10.f, delta, delta, 1.f);*/
    /*gl_FragColor = vec4(diff, diff, diff, 1.0f);*/
    /*gl_FragColor = vec4(distanceFromLight, distanceFromLight, distanceFromLight, 1.f);*/
}


