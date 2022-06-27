#version 100

#define MAX_BONE_NUM 73

attribute highp vec4 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;
attribute vec4 inBlendIndices;
attribute vec3 inBlendWeights;

uniform mat4 matWVP;
uniform mat4 matWorld;
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec3 subLightDir;
uniform vec4 subLightColor;
uniform vec4 brightness;
uniform vec4 positionColor;
uniform vec4 ambient;
uniform vec4 boneMatRows[3*MAX_BONE_NUM];

varying vec4 color;
varying vec4 worldPos;
varying vec3 normal;
varying vec2 texCoord;
varying vec3 vMainLightDir;
varying vec4 vMainLightColor;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

varying vec4 oFogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#endif

vec3 MulBone3( vec3 vInputPos, int nMatrix, float fBlendWeight )
{
    vec3 vResult;
    vResult.x = dot( vInputPos, boneMatRows[3*nMatrix+0].xyz );
    vResult.y = dot( vInputPos, boneMatRows[3*nMatrix+1].xyz );
    vResult.z = dot( vInputPos, boneMatRows[3*nMatrix+2].xyz );
    return vResult * fBlendWeight;
}

vec3 MulBone4( vec4 vInputPos, int nMatrix, float fBlendWeight )
{
    vec3 vResult;
    vResult.x = dot( vInputPos, boneMatRows[(3*nMatrix)+0].xyzw );
    vResult.y = dot( vInputPos, boneMatRows[(3*nMatrix)+1].xyzw );
    vResult.z = dot( vInputPos, boneMatRows[(3*nMatrix)+2].xyzw );
    return vResult * fBlendWeight;
}

void main(void)
{
	vec3 vPos;
	vec3 vNorm;
	vec4 vWorldPos;
    ivec3 BoneIndices;

	BoneIndices.x = int(inBlendIndices.x);
	BoneIndices.y = int(inBlendIndices.y);
	BoneIndices.z = int(inBlendIndices.z);
	
  	vPos = MulBone4(inPosition, BoneIndices.x, inBlendWeights.x)
  	 + MulBone4(inPosition, BoneIndices.y, inBlendWeights.y)
  	 + MulBone4(inPosition, BoneIndices.z, inBlendWeights.z);
	
	vNorm = MulBone3(inNormal, BoneIndices.x, inBlendWeights.x)
	 + MulBone3(inNormal, BoneIndices.y, inBlendWeights.y)
	 + MulBone3(inNormal, BoneIndices.z, inBlendWeights.z);
	// blend vertex position & normal
	
	vWorldPos = matWorld * vec4(vPos, 1.0);
	
	gl_Position = matWVP * vec4(vPos, 1.0);
	texCoord = inTexCoord;
	
	vNorm = normalize(mat3(matWorld)*vNorm);
	
	float mainParam = max(dot(mainLightDir, vNorm), 0.0);
	float subParam = max(dot(subLightDir, vNorm), 0.0);
	
	vec4 brightnessEx;
	//float bScale = 0.6;
	//brightnessEx.r = pow(clamp(brightness.r * bScale , 1.1, brightness.r * bScale), 2.0);//clamp((brightness.r + 0.2), 0.0, 1.0);//make sure actor brightness +0.2 than block...
	//brightnessEx.g = pow(clamp(brightness.g * bScale , 1.1, brightness.g * bScale), 2.0);//clamp((brightness.g + 0.2), 0.0, 1.0);
	//brightnessEx.b = pow(clamp(brightness.b * bScale , 1.1, brightness.b * bScale), 2.0);//clamp((brightness.b + 0.2), 0.0, 1.0);
	brightnessEx.r = max(brightness.r + 0.2, brightness.r * 1.3);//make sure actor brightness +0.2 than block...
	brightnessEx.g = max(brightness.g + 0.2, brightness.g * 1.3);
	brightnessEx.b = max(brightness.b + 0.2, brightness.b * 1.3);
	brightnessEx.a = brightness.a;

	color = mainParam * mainLightColor + subParam * subLightColor + ambient;
	color.a = 1.0;
	color = color * brightnessEx * positionColor;
#ifndef NEW_FOG
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif

	normal = vNorm;
	worldPos=vWorldPos;
	vMainLightDir = mainLightDir;
	vMainLightColor = mainLightColor;
}
