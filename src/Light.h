#ifndef mce_light
#define mce_light

#include "graphics.h"
#include "point.h"

class light_t
	{
	GLenum id;

	GLfloat constant, linear, quadratic; // attenuation
	GLfloat position[4];

	GLfloat ambient[4];
	GLfloat diffuse[4];
	GLfloat specular[4];

	static bool inUse[8];
	
public:
	light_t( const vector_t& pos = vector_t(0.0, 0.0, 0.0, 1.0));
	light_t(const vector_t &pos, const vector_t &am, const vector_t &diff, const vector_t &spec);
	~light_t();

	void set_ambient(const vector_t &am);
	void set_diffuse(const vector_t &diff);
	void set_specular(const vector_t &spec);
	void set_pos(const vector_t &pos);
	void on();
	void off();
	
	void moveTo( const vector_t& pos );
	};

#endif
