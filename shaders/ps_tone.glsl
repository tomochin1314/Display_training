//TODO: the alpha of the return color of function tone is not 1.0
varying vec3 normal;
varying vec3 light0_dir, light1_dir, light2_dir, light3_dir, eye_vec;
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

// cold and warm color
const vec4 cold = vec4(0.0f, 0.f, 1.0f, 1.0f);
const vec4 warm = vec4(1.0f, 1.0f, 0.0f, 1.0f);

vec4 tone(vec4 cwarm, vec4 ccold)
{
    vec3 n = normalize(normal);
    vec3 l0 = normalize(light0_dir);
    vec3 l1 = normalize(light1_dir);
    vec3 l2 = normalize(light2_dir);
    vec3 l3 = normalize(light3_dir);

    float intensity = dot( l0, n );

    float full_intensity = dot(l0,n)+dot(l1,n)+dot(l2,n)+dot(l3,n);
    full_intensity *= 0.25;

    vec4 color = ( (1.f + full_intensity) / 2.f ) * ccold
        + ( 1.f - (1.f + full_intensity) / 2.0f ) * cwarm;

    /*vec4 color = mix(cwarm, ccold, intensity);*/

    vec3 E = normalize( eye_vec );
    vec3 R = reflect(-l0, n);

    // for light0's specular
    if(intensity > 0.0)
    {
        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += light0_specular * gl_FrontMaterial.specular
            * specular;
    }

    // for light1's specular
    intensity = dot( l1, n );
    R = reflect(-l1, n);

    if(intensity > 0.0)
    {
        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += light1_specular * gl_FrontMaterial.specular
            * specular;
    }

    // for light2's specular
    intensity = dot( l2, n );
    R = reflect(-l2, n);

    if(intensity > 0.0)
    {
        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += light2_specular * gl_FrontMaterial.specular
            * specular;
    }

    // for light3's specular
    intensity = dot( l3, n );
    R = reflect(-l3, n);

    if(intensity > 0.0)
    {
        float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
        color += light3_specular * gl_FrontMaterial.specular
            * specular;
    }

    return color;
}

void main()
{

    vec4 color;

    //
    // @ warm = yellow; cold = blue;
    // @ the formula is cwarm = warm * y + alpha * kd
    //                ccold = cold * b + beta * kd
    // @ here kd is red
    // @ y and b determine the strength of the overall temperature shift
    //   alpha and beta determine the prominance of the object color and the strength
    //   of the luminance shift
    //
    vec4 cwarm = min( warm * 0.6  + vec4(1.f, 0., 0., 1.) * 0.6,  1.0f); 
    vec4 ccold = min( cold * 0.6 + vec4(1., 0., 0., 1.) * 0.2, 1.0f);


    if(gl_Color == keycolor)
        gl_FragColor = gl_Color * max(0.f, dot( normalize(light0_dir), normalize(normal) ) );
    else
        gl_FragColor = vec4(tone(cwarm, ccold).xyz, 1.f) * gl_Color;

}
