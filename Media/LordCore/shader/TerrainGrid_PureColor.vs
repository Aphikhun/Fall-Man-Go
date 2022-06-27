#version 100

attribute highp vec4 inPosition;

uniform mat4 matVP;

void main()
{
	gl_Position = matVP * vec4(inPosition.xyz, 1.0);
}

