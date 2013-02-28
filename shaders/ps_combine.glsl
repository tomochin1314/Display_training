
uniform sampler2D shadow_mask;
uniform sampler2D ao_map;

varying vec4 tex_coord_shadow;
varying vec4 tex_coord_ao;
varying vec3 normal, light0_dir, light1_dir, light2_dir, light3_dir, eye_vec;

vec4 phong(vec4 color, vec3 n)
{
	vec3 N = normalize(n);
	vec3 L0 = normalize(light0_dir);
	vec3 L1 = normalize(light1_dir);
	vec3 L2 = normalize(light2_dir);
	vec3 L3 = normalize(light3_dir);

	float lambert_term0 = dot(N,L0);
	float lambert_term1 = dot(N,L1);
	float lambert_term2 = dot(N,L2);
	float lambert_term3 = dot(N,L3);

    vec3 E, R;

    // the first light
	if(lambert_term0 > 0.0)
	{
		color += gl_LightSource[0].diffuse * gl_Color//gl_FrontMaterial.diffuse
		               * lambert_term0;

        E = normalize( eye_vec );
        R = normalize(reflect(-L0, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += gl_LightSource[0].specular * gl_FrontMaterial.specular
                       * specular;
	}


    // the second light
    if(lambert_term1 > 0.0)
    {
        color += gl_LightSource[1].diffuse * gl_Color//gl_FrontMaterial.diffuse
                        * lambert_term1;

        E = normalize( eye_vec );
        R = normalize(reflect(-L1, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += gl_LightSource[1].specular * gl_FrontMaterial.specular
                        * specular;
    }

    // the third light
    if(lambert_term2 > 0.0)
    {
        color += gl_LightSource[2].diffuse * gl_Color//gl_FrontMaterial.diffuse
            * lambert_term2;

        E = normalize( eye_vec );
        R = normalize(reflect(-L2, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += gl_LightSource[2].specular * gl_FrontMaterial.specular
            * specular;
    }

    // the fourth light
    if(lambert_term3 > 0.0)
    {
        color += gl_LightSource[3].diffuse * gl_Color//gl_FrontMaterial.diffuse
            * lambert_term3;

        E = normalize( eye_vec );
        R = normalize(reflect(-L3, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += gl_LightSource[3].specular * gl_FrontMaterial.specular
            * specular;
    }

    return color;

}

void main() 
{
	vec4 init_color = ( gl_FrontLightModelProduct.sceneColor * 
	                     gl_FrontMaterial.ambient ) + 
					   ( gl_LightSource[0].ambient  * gl_FrontMaterial.ambient +
                         gl_LightSource[1].ambient * gl_FrontMaterial.ambient +  
                         gl_LightSource[2].ambient * gl_FrontMaterial.ambient +  
                         gl_LightSource[3].ambient * gl_FrontMaterial.ambient);

/*
 *
 *    vec4 shadowcoord = tex_coord_shadow / tex_coord_shadow.w ;
 *    [>shadowCoordinateWdivide.z += 0.0005;<]
 *    float mask = texture2D(shadow_mask,  shadowcoord.st).x;
 *    float shadow_factor = 1.0f;
 *    if(mask > 0.f)
 *        shadow_factor = 0.2f;
 */

    vec4 ao_coord = tex_coord_ao / tex_coord_ao.w;
    float ao_factor = texture2D(ao_map, ao_coord.st).x;


    if(gl_FrontFacing)
    {
        gl_FragColor = ao_factor * phong(init_color, normal);
        /*gl_FragColor = vec4(ao_factor, 0.f, 0.f, 1.f);*/
    }
    else
    {
        gl_FragColor = ao_factor * phong(init_color, -normal);
        /*gl_FragColor = vec4(ao_factor, 0.f, 0.f, 1.f);*/
    }


    /*gl_FragColor = color;*/
    /*gl_FragColor = 0.5*gl_Color;*/
    /*gl_FragColor = vec4(0.2, 0.1, 0.1, 1.0);*/
    /*gl_FragColor = gl_FrontMaterial.diffuse;*/
}


