
uniform sampler2D shadow_mask;

varying vec4 tex_coord_shadow;

varying vec3 normal, light0_dir, light1_dir, light2_dir, light3_dir, eye_vec;

// eye light
const vec4 light0_diff = vec4(0.6f, 0.6f, 0.6f, 1.0);
const vec4 light0_specular = vec4(1.f, 1.f, 1.f, 1.f);
const vec4 light0_ambient = vec4(0.f, 0.f, 0.f, 1.f);

// the overhead light
const vec4 light1_diff = vec4(0.2, 0.2, 0.2, 1.0);
const vec4 light1_specular = vec4(1.f, 1.f, 1.f, 1.f);
const vec4 light1_ambient = vec4(0.f, 0.f, 0.f, 1.f);

// left top light
const vec4 light2_diff = vec4(0.1, 0.1, 0.1, 1.0);
const vec4 light2_specular = vec4(1.f, 1.f, 1.f, 1.f);
const vec4 light2_ambient = vec4(0.f, 0.f, 0.f, 1.f);

// right top light
const vec4 light3_diff = vec4(0.1, 0.1, 0.1, 1.0);
const vec4 light3_specular = vec4(1.f, 1.f, 1.f, 1.f);
const vec4 light3_ambient = vec4(0.f, 0.f, 0.f, 1.f);


// if gl_Color equals to keycolor, we don't apply any effect
const vec4 keycolor = vec4(1.f, 1.f, 0.f, 1.f);

vec4 phong(vec3 n)
{
    vec4 color = vec4(0.f, 0.f, 0.f, 1.f);

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
    E = normalize( eye_vec );

    // the first light
	if(lambert_term0 > 0.0)
	{
		color += light0_diff * gl_Color//gl_FrontMaterial.diffuse
		               * lambert_term0;

        R = normalize(reflect(-L0, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += light0_specular * gl_FrontMaterial.specular
                       * specular;
	}


    // the second light
    if(lambert_term1 > 0.0)
    {
        color += light1_diff * gl_Color//gl_FrontMaterial.diffuse
                        * lambert_term1;

        R = normalize(reflect(-L1, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += light1_specular * gl_FrontMaterial.specular
                        * specular;
    }

    // the third light
    if(lambert_term2 > 0.0)
    {
        color += light2_diff * gl_Color//gl_FrontMaterial.diffuse
            * lambert_term2;

        R = normalize(reflect(-L2, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += light2_specular * gl_FrontMaterial.specular
            * specular;
    }

    // the fourth light
    if(lambert_term3 > 0.0)
    {
        color += light3_diff * gl_Color//gl_FrontMaterial.diffuse
            * lambert_term3;

        R = normalize(reflect(-L3, N));

        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += light3_specular * gl_FrontMaterial.specular
            * specular;
    }

    return color;

}


void main() 
{

    vec4 shadowCoordinateWdivide = tex_coord_shadow / tex_coord_shadow.w ;
    /*shadowCoordinateWdivide.z += 0.0005;*/
    float mask = texture2D(shadow_mask,  shadowCoordinateWdivide.st).x;
    float shadow_factor = 1.0f;
    if(mask > 0.f)
        shadow_factor = 0.5f;


    if(gl_FrontFacing)
    {
        if(gl_Color == keycolor)
            gl_FragColor = vec4(shadow_factor * gl_Color.xyz, 1.0f);
        else
            gl_FragColor = vec4(shadow_factor * phong(normal).xyz, 1.0f);
    }
    else
    {
        if(gl_Color == keycolor)
            gl_FragColor = vec4(shadow_factor * gl_Color.xyz, 1.0f);
        else
            gl_FragColor = vec4(shadow_factor * phong(-normal).xyz, 1.0f);
    }

}



