#version 100

#define MAX_BONE_NUM 73

attribute highp vec4 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;
attribute vec4 inBlendIndices;
attribute vec3 inBlendWeights;

uniform mat4 matWVP;

varying vec3 tempValue;

void main(void)
{
	vec3 vPos;
	
	// blend vertex position
	vec4 posV4 = vec4(inPosition.xyz, 1.0);
	
	tempValue = inNormal * 0.000001;
	tempValue.xy += inTexCoord * 0.000001;
	gl_Position = matWVP * posV4;
}