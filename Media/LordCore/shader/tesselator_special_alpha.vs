#version 100

attribute highp vec4 inPosition;
attribute vec2 inTexCoord;
attribute vec4 inColor;

uniform mat4 matWVP;
uniform vec4 sectionPos;

varying vec2 texCoord_texture;
varying vec3 color;

void main(void)
{
	vec3 blockPos;
	blockPos = inPosition.xyz / 15.0;
	
	// output position.
	blockPos = sectionPos.xyz + blockPos;
	gl_Position = matWVP * vec4(blockPos, 1.0);
	texCoord_texture = inTexCoord / 32768.0;
    color = inColor.rgb / 255.0;
}

