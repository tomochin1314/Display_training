/** @file ps_toon.glsl
 * 
 *  @brief Pixel shader for toon shading.
 *
 *  Your description here
 *
 *  @author <Your name> (andrewid)
 *  @bug <Fill in your bugs here.>
 */

uniform vec3 mat_diffuse;        // diffuse material of the object.
uniform vec3 mat_specular;       // specular material of the object.
varying vec3 normal;

/* phong lighting components */
varying float phong_diffuse, phong_specular, phong_edge;
varying vec3 light_dir, eye_vec;

void main()
{
	/* TODO: Delete and replace with your own implementation */

	float intensity;
	vec4 color;
	vec4 cwarm = min( vec4(1, 1, 0, 1)*0.3 + gl_FrontMaterial.diffuse * 0.5, 1.0f); // the warm color, use the object's color
	vec4 ccold = min( vec4(0, 0, 1, 1) * 0.55 + gl_FrontMaterial.diffuse * 0.25, 1.0f);

	// for the silhouette
	vec4 outline_color = vec4(0,0,0,1); // black

	vec3 n = normalize(normal);
	vec3 l = normalize(light_dir);
	intensity = dot( l, n );

	color = ( (1.f + intensity) / 2.f ) * ccold 
		+ ( 1.f - (1.f + intensity) / 2.0f ) * cwarm; 

	vec3 E = normalize( eye_vec );
	vec3 R = reflect(-l, n);

	if(intensity > 0.0)
	{
		float specular = pow( max( dot(R,E), 0.0), gl_FrontMaterial.shininess );
		color += gl_LightSource[0].specular * gl_FrontMaterial.specular
			* specular;
	}


	gl_FragColor = color;

	/* END TODO */
}
