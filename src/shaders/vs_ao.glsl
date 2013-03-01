//
// this is the vertex shader for ambient occlusion
//
// XLM


attribute float accessibility;

varying vec4  diffuse;

void main()
{
	vec3 ec_pos = vec3(gl_ModelViewMatrix * gl_Vertex);
	vec3 tnorm = normalize(gl_NormalMatrix * gl_Normal);
	vec3 light_vec = normalize(vec3(gl_LightSource[0].position) - ec_pos);
	float costheta = dot(tnorm, vec3(gl_LightSource[0].position));
	float a = 0.5 + 0.5 * costheta;

    diffuse = mix(gl_FrontMaterial.diffuse, vec4(0,0,0,1), a) * accessibility;

	gl_Position = ftransform();
	
}
