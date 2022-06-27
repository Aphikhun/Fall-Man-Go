#version 100

attribute highp vec4 inPosition;
attribute vec3 inNormal;
attribute vec4 inColor;
attribute vec2 inTexCoord;
attribute vec2 inTexCoord1;

uniform vec4 UVDirect;
uniform mat4 matVP;
uniform	mat4 SMProjectMatrix;

varying vec4 blendines;
varying vec2 texCoord;
varying vec2 texCoord1;
//varying vec2 texCoord2;
varying vec3 oWPos;
varying	vec4 oShadowPosSM;
varying vec3 tangentX;
varying vec3 tangentY;
varying vec3 tangentZ;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

varying vec4 ofogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#endif

vec4 ComputeShadowPos(vec4 WorldPos, mat4 SMProjectMatrix)
{
	vec4 ret = SMProjectMatrix * WorldPos;
	ret.xyz /= ret.w;

	ret.x = ret.x * 0.5 + 0.5;
	ret.y = ret.y * 0.5 + 0.5;
	ret.z = ret.z * 0.5 + 0.5;
	return ret;
}

void main()
{
	gl_Position = matVP * vec4(inPosition.xyz, 1.0);
    blendines = inColor;
    texCoord = inTexCoord;
    texCoord1 = inTexCoord1;
	//texCoord2 = vec2(inPosition.y, dot(normalize(UVDirect.zw), inPosition.xz)) * UVDirect.xy;
#ifndef NEW_FOG
	ofogColor = vec4(fogParam[1].rgb, ComputeFog(inPosition.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif

	oWPos = inPosition.xyz;
	oShadowPosSM = ComputeShadowPos(vec4(oWPos, 1.0), SMProjectMatrix);
	
    tangentZ = inNormal;
    tangentY = normalize(cross(vec3(1.0, 0.0, 0.0), tangentZ));
    tangentX = normalize(cross(tangentZ, tangentY));
}

