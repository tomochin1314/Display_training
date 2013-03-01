

varying vec3 normal, light0_dir, light1_dir, light2_dir, light3_dir, eye_vec;

void main() 
{
	vec4 final_color = ( gl_FrontLightModelProduct.sceneColor * 
	                     gl_FrontMaterial.ambient ) + 
					   ( gl_LightSource[0].ambient  * gl_FrontMaterial.ambient +
                        gl_LightSource[1].ambient * gl_FrontMaterial.ambient +  
                        gl_LightSource[2].ambient * gl_FrontMaterial.ambient +  
                        gl_LightSource[3].ambient * gl_FrontMaterial.ambient);

	vec3 N = normalize(normal);
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
		final_color += gl_LightSource[0].diffuse * gl_Color//gl_FrontMaterial.diffuse
		               * lambert_term0;

		E = normalize( eye_vec );
		R = normalize(reflect(-L0, N));

		float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
		final_color += gl_LightSource[0].specular * gl_FrontMaterial.specular
		               * specular;
	}


    // the second light
    if(lambert_term1 > 0.0)
    {
        final_color += gl_LightSource[1].diffuse * gl_Color//gl_FrontMaterial.diffuse
                        * lambert_term1;

        E = normalize( eye_vec );
        R = normalize(reflect(-L1, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        final_color += gl_LightSource[1].specular * gl_FrontMaterial.specular
                        * specular;
    }

    // the third light
    if(lambert_term2 > 0.0)
    {
        final_color += gl_LightSource[2].diffuse * gl_Color//gl_FrontMaterial.diffuse
            * lambert_term2;

        E = normalize( eye_vec );
        R = normalize(reflect(-L2, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        final_color += gl_LightSource[2].specular * gl_FrontMaterial.specular
            * specular;
    }

    // the fourth light
    if(lambert_term3 > 0.0)
    {
        final_color += gl_LightSource[3].diffuse * gl_Color//gl_FrontMaterial.diffuse
            * lambert_term3;

        E = normalize( eye_vec );
        R = normalize(reflect(-L3, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        final_color += gl_LightSource[3].specular * gl_FrontMaterial.specular
            * specular;
    }


    gl_FragColor = final_color;
    /*gl_FragColor = gl_FrontMaterial.diffuse;*/
}
