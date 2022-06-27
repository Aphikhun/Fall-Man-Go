#version 100

attribute highp vec3 inPosition;
attribute vec4 inColor;
attribute vec2 inTexCoord;
attribute vec4 inBrightness;

uniform mat4 matWVP;

varying vec4 color;
varying vec2 texCoord;
varying vec4 brightness;

void main(void)
{
	gl_Position = matWVP * vec4(inPosition, 1.0);

	color = inColor;
	texCoord = inTexCoord;
	brightness = inBrightness;
}