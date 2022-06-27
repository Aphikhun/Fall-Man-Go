#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec3 inTexCoord;
attribute vec3 inTexCoord1;
attribute vec3 inTexCoord2;

uniform mat4 matWVP;

invariant gl_Position;

void main(void)
{
	gl_Position = matWVP * vec4(inPosition, 1.0);
}

