#version 100

attribute highp vec4 inPosition;

uniform mat4 matWVP;

void main(void)
{
	gl_Position = matWVP * vec4(inPosition.xyz, 1.0);
}