#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;

uniform mat4 matVP;

varying mediump vec4 color;
varying mediump vec2 texCoord;

invariant gl_Position;


void main(void)
{
    texCoord = inTexCoord;
	color = vec4(1.0, 1.0, 1.0, 1.0);
	gl_Position = matVP * vec4(inPosition, 1.0);
}
