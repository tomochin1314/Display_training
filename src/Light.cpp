#include "Light.h"

bool light_t::inUse[8] = { false };

static int asInt( GLenum id )
{
	switch ( id )
	{
		case GL_LIGHT0: return 0;
		case GL_LIGHT1: return 1;
		case GL_LIGHT2: return 2;
		case GL_LIGHT3: return 3;
		case GL_LIGHT4: return 4;
		case GL_LIGHT5: return 5;
		case GL_LIGHT6: return 6;
		case GL_LIGHT7: return 7;
		default: throw;
	}
}

static GLenum asEnum( int id )
{
	switch ( id )
	{
		case 0: return GL_LIGHT0;
		case 1: return GL_LIGHT1;
		case 2: return GL_LIGHT2;
		case 3: return GL_LIGHT3;
		case 4: return GL_LIGHT4;
		case 5: return GL_LIGHT5;
		case 6: return GL_LIGHT6;
		case 7: return GL_LIGHT7;
		default: throw;
	}
}

light_t::light_t( const vector_t& pos )
{
	constant=1;linear=1; quadratic=1;
	position[0]=(GLfloat)pos.x;position[1]=(GLfloat)pos.y;
	position[2]=(GLfloat)pos.z;position[3]= 0.f; // directional (1.f for point light)
	ambient[0]=(GLfloat)0.;ambient[1]=(GLfloat)0.; 
	ambient[2]=(GLfloat)0.;ambient[3]=(GLfloat)1.;
	diffuse[0]=(GLfloat)1.;diffuse[1]=(GLfloat)1.; 
	diffuse[2]=(GLfloat)1.;diffuse[3]=(GLfloat)1.;
	specular[0]=(GLfloat)1.;specular[1]=(GLfloat)1.; 
	specular[2]=(GLfloat)1.;specular[3]=(GLfloat)1.;

	// find first unused GL light
	for ( id = 0; inUse[id]; ++id )
		;
	inUse[id] = true;
	id = asEnum( id );
}

light_t::light_t(const vector_t &pos, const vector_t &am, const vector_t &diff, const vector_t &spec)
{
	set_pos(pos);
	set_ambient(am);
	set_diffuse(diff);
	set_specular(spec);
}

void light_t::set_pos(const vector_t &pos)
{
	position[0] = pos[0];
	position[1] = pos[1];
	position[2] = pos[2];
	position[3] = 1.f;
}

void light_t::set_diffuse(const vector_t &diff)
{
	diffuse[0] = diff[0];
	diffuse[1] = diff[1];
	diffuse[2] = diff[2];
	diffuse[3] = 1.f;
}

void light_t::set_specular(const vector_t &spec)
{
	specular[0] = spec[0];
	specular[1] = spec[1];
	specular[2] = spec[2];
	specular[3] = 1.f;
}

void light_t::set_ambient(const vector_t &am)
{
	ambient[0] = am[0];
	ambient[1] = am[1];
	ambient[2] = am[2];
	ambient[3] = 1.f;
}

light_t::~light_t()
{
	inUse[ asInt( id )] = false;
}

void light_t::on()
{
	glEnable( id );

	// state set here instead of constructor so that Light objects can be created at any time
	// turn them on only when an OpenGL context is active!

	glLightf( id, GL_CONSTANT_ATTENUATION, constant );
	glLightf( id, GL_LINEAR_ATTENUATION, linear );
	glLightf( id, GL_QUADRATIC_ATTENUATION, quadratic );
	glLightfv( id, GL_POSITION, position );
	glLightfv( id, GL_AMBIENT, ambient );
	glLightfv( id, GL_DIFFUSE, diffuse );
	glLightfv( id, GL_SPECULAR, specular );
}

void light_t::off()
{
	glDisable( id );
}

void light_t::moveTo( const vector_t& pos )
{
	position[0] = pos.x;
	position[1] = pos.y;
	position[2] = pos.z;
	glLightfv( id, GL_POSITION, position );
}
