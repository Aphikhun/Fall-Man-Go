#version 100

attribute highp vec3 inPosition;

//uniform mat4 matWorld;
uniform mat4 matVP;
//uniform mat4 matWVP;

invariant gl_Position;

void main(void)
{
	gl_Position = matVP * vec4(inPosition, 1.0); //matWVP
}
