#version 100

attribute highp vec4 inPosition;
attribute vec2 inTexCoord;
attribute vec4 inColor1;
attribute vec4 inColor;
attribute vec4 inNormal;

uniform mat4 matWVP;
uniform vec4 sectionPos;
varying vec2 texCoord_texture;

void main(void)
{
	vec3 blockPos = inPosition.xyz / 2048.0;	
	blockPos = sectionPos.xyz + blockPos;
	gl_Position = matWVP * vec4(blockPos, 1.0);

	texCoord_texture = inTexCoord / 2048.0;
	texCoord_texture.x +=  inColor1.x * 0.000001 + inColor.x * 0.000001 + inNormal.x*0.00001;
}

