#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;

uniform mat4 matW;
uniform mat4 matVP;

void main(void)
{
	mat4 matWVP = matVP * matW;
	gl_Position = matWVP * vec4(inPosition, 1.0)
		+ vec4( inNormal, 0.0) + vec4( inTexCoord, 0.0, 0.0) 
		- vec4( inNormal, 0.0) - vec4( inTexCoord, 0.0, 0.0);;
}