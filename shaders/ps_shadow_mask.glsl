
// at most 8 depth map
uniform sampler2D depth_map0;
uniform sampler2D depth_map1;
uniform sampler2D depth_map2; // the largest relocation scale
uniform float depth_far;
uniform float depth_near;
uniform vec4 threshold0;
uniform vec4 reloc_scale0;
varying float camera_depth;
varying vec4 tex_coord;

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

    float ref_dist = abs(camera_depth - dist2);
    float diff = ref_dist;
    float scale = reloc_scale0.z;

    if(ref_dist <= thre.x)
    {
        diff = abs(camera_depth - dist0);
        scale = reloc_scale0.x;
    }
    else if(ref_dist <= thre.y)
    {
        diff = abs(camera_depth - dist1);
        scale = reloc_scale0.y;
    }
    else if(ref_dist <= thre.z)
    {
        diff = ref_dist;
        scale = reloc_scale0.z;
    }
    else
    {
        diff = 0.f;
    }

    float delta = (2.*scale) / depth_diff;

    float shadow = 0.0;
    if (tex_coord.w > 0.0 && diff > delta)
    {
        shadow = 1.0f;
    }
    
    /*gl_FragDepth = shadow * diff;*/
    if(shadow * diff == 0.f)
        gl_FragColor = vec4(0.f, 1.f, 0.f, 1.f);
    else gl_FragColor = vec4(1.f, 0.f, 0.f, 1.f);
     /*gl_FragColor = vec4(shadow*diff, 0.f, 0.f, 1.f);*/
     /*gl_FragColor = vec4(1.f, 0.f, 0.f, 1.f);*/
    /*gl_FragDepth = tex_coord_divided;*/
    /*gl_FragDepth = 0.1;*/
}
