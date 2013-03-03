
// at most 8 depth map
uniform sampler2D depth_map0;
uniform sampler2D depth_map1;
uniform sampler2D depth_map2; // the largest relocation scale
uniform sampler2D depth_map3; // the largest relocation scale
uniform float depth_far;
uniform float depth_near;
uniform vec4 threshold0;
uniform vec4 reloc_scale0;
varying float camera_depth;
varying vec4 tex_coord;

// the larger the distance between two tubes
// the wider and lighter the shadow
void main()
{
    vec4 tex_coord_divided = tex_coord / tex_coord.w;
    float depth_diff = depth_far - depth_near;

    // set the parameters
    vec4 thre = threshold0;

    thre.x= threshold0.x / depth_diff;
    thre.y= threshold0.y / depth_diff;
    thre.z= threshold0.z / depth_diff;
    thre.w= threshold0.w / depth_diff;

    float dist0 = texture2D(depth_map0, tex_coord_divided.st).x;
    float dist1 = texture2D(depth_map1, tex_coord_divided.st).x;
    float dist2 = texture2D(depth_map2, tex_coord_divided.st).x;
    float dist3 = texture2D(depth_map3, tex_coord_divided.st).x;

    float ref_dist = abs(camera_depth - dist3);
    float diff = ref_dist;
    float scale = reloc_scale0.w;
    float shadow_tone;  // smaller distance, lighter shadow

    // compare the distance between two tubes with each limit
    if(ref_dist <= thre.x)
    {
        diff = abs(camera_depth - dist0);
        scale = reloc_scale0.x;
        shadow_tone = 0.3;
    }
    else if(ref_dist <= thre.y)
    {
        diff = abs(camera_depth - dist1);
        scale = reloc_scale0.y;
        shadow_tone = 0.5;
    }
    else if(ref_dist <= thre.z)
    {
        diff = abs(camera_depth - dist2);
        scale = reloc_scale0.z;
        shadow_tone = 0.65;
    }
    else if(ref_dist <= thre.w)
    {
        diff = ref_dist;
        scale = reloc_scale0.w;
        shadow_tone = 0.7;
    }
    else  // if the distance if too large, we don't draw any shadow
    {
        diff = 0.f;
    }

    // 4.0 is a magic number to avoid false shadow on the object its self
    float delta = (4.*scale) / depth_diff;

    float shadow = 0.0;
    if (tex_coord.w > 0.0 && diff > delta)
    {
        shadow = 1.0f;
    }
    
    /*gl_FragDepth = shadow * diff;*/
    /*
     *if(shadow * diff == 0.f)
     *    gl_FragColor = vec4(0.f, 1.f, 0.f, 1.f);
     *else gl_FragColor = vec4(shadow_tone, 0.f, 0.f, 1.f);
     */
    if(shadow * diff == 0.f)
        gl_FragDepth = 0.;
    else gl_FragDepth = shadow_tone;
}
