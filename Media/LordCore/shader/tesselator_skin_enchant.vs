#version 100

#define MAX_BONE_NUM 73

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec4 inColor;
attribute vec2 inTexCoord;
attribute float inBlendIndices;

uniform mat4 matWVP;
uniform mat4 matWorld;
uniform mat4 matTexture1;
uniform mat4 matTexture2;
uniform vec4 texAtlas;
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec3 subLightDir;
uniform vec4 subLightColor;
uniform vec4 brightness;
uniform vec4 ambient;
uniform vec4 boneMatRows[3*MAX_BONE_NUM];

varying vec4 color;
varying vec2 texCoord1;
varying vec2 texCoord2;

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

vec3 MulBone3(vec3 vInputPos, int nMatrix)
{
    vec3 vResult;
    vResult.x = dot( vInputPos, boneMatRows[3*nMatrix+0].xyz );
    vResult.y = dot( vInputPos, boneMatRows[3*nMatrix+1].xyz );
    vResult.z = dot( vInputPos, boneMatRows[3*nMatrix+2].xyz );
    return vResult;
}

vec3 MulBone4(vec4 vInputPos, int nMatrix)
{
    vec3 vResult;
    vResult.x = dot( vInputPos, boneMatRows[(3*nMatrix)+0].xyzw );
    vResult.y = dot( vInputPos, boneMatRows[(3*nMatrix)+1].xyzw );
    vResult.z = dot( vInputPos, boneMatRows[(3*nMatrix)+2].xyzw );
    return vResult;
}

void main(void)
{
	vec3 vPos;
	vec4 vWorldPos;
	vec3 vNorm;
	vec4 vTexture;
	vec4 vEnchantTex;
	int BoneIndices = int(inBlendIndices);

	vPos = MulBone4(vec4(inPosition, 1.0), BoneIndices);
	vWorldPos = matWorld * vec4(vPos, 1.0);
	vNorm = MulBone3(inNormal, BoneIndices);
	vNorm = mat3(matWorld) * vNorm;
	vNorm = normalize(vNorm);
	
	gl_Position = matWVP * vec4(vPos, 1.0);

	vTexture.x = (inTexCoord.x - texAtlas.x) / texAtlas.z;
	vTexture.y = (inTexCoord.y - texAtlas.y) / texAtlas.w;
	vTexture.z = 1.0;
	vTexture.w = 1.0;
	vEnchantTex = matTexture1 * vTexture;
	texCoord1 = vEnchantTex.xy;
	vEnchantTex = matTexture2 * vTexture;
	texCoord2 = vEnchantTex.xy;
	
	float mainParam = max(dot(mainLightDir, vNorm), 0.0);
	float subParam = max(dot(subLightDir, vNorm), 0.0);

	color = mainParam * mainLightColor + subParam * subLightColor;
	color = (color + ambient) * inColor * brightness;
#ifndef NEW_FOG
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif
}

