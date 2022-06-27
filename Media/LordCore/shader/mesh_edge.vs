#version 100

attribute highp vec3 inPosition;

uniform mat4 matWVP;

void main(void)
{
	gl_Position = matWVP * vec4(inPosition, 1.0);
}