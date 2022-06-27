#version 100

attribute highp vec3 inPosition;
attribute vec3 inTexCoord;
attribute vec3 inTexCoord2;	// WorldPos
attribute vec2 inNormal;
attribute vec3 inTexCoord1;
attribute vec4 inColor;

uniform vec3	c_GrassUSScale;
uniform mat4 	matVP;		// VP
uniform vec3	fogPos;

varying vec2 	texCoord;
varying vec4	verColor;
varying vec3	transColor;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

varying vec4 fogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#endif

void main(void)
{
	// 1. Calculate the local waved position:
	float scale = inNormal.x;
	float angle = inNormal.y;
	
	float radiansAngle = radians(angle);
	float cosAngle = cos(radiansAngle);
	float sinAngle = sin(radiansAngle);
	
	mat4 matInW = mat4(scale * cosAngle,	0.0,			-scale * sinAngle,	0.0,
						0.0, 				scale, 			0.0, 				0.0,
						scale * sinAngle, 	0.0, 			scale * cosAngle, 	0.0,
						inTexCoord2.x, 		inTexCoord2.y,	inTexCoord2.z, 		1.0);
						
	vec4 pos = vec4(inPosition, 1.0);

	vec3 worldPos = (matInW*pos).xyz;
	gl_Position = matVP * vec4(worldPos, 1.0);
	
	vec2 uvScale_t = vec2(c_GrassUSScale.x, c_GrassUSScale.y * inTexCoord1.z);
	texCoord = (inTexCoord.xy + inTexCoord1.xy + 0.02) * uvScale_t.xy;

	verColor = inColor;

	transColor = vec3(0.0, 0.0, 0.0);

	// Fog color.
	
#ifndef NEW_FOG
	fogColor =  vec4(fogParam[1].rgb, ComputeFog(worldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif
}