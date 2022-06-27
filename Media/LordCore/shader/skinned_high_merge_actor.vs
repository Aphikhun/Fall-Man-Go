#version 300 es

precision mediump float;

//#include "headers/basic.glsl"
#include "headers/math/matrix.glsl"													// 教程版会用到
//#include "headers/skinned.glsl"
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#include "headers/fog.glsl"

#define MAX_BONE_NUM 50

in highp vec4 inPosition;
in vec3 inNormal;
in vec3 inTexCoord;
in vec4 inBlendIndices;
in vec3 inBlendWeights;

uniform vec4 multiCalColor;
uniform vec4 boneMatRows[3*MAX_BONE_NUM];
uniform mat4 merge_worldProj[20];
uniform mat4 merge_viewProj;

out vec3 worldPos;
out vec3 worldNormal;
out vec2 texCoord;
out float useOverlayColorReplaceMode;
out float meshIndex;

invariant gl_Position;

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

	meshIndex = inTexCoord.z;
	int matIndex = int(inTexCoord.z);
	mat4 matWorld = merge_worldProj[matIndex];
	
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
	vNorm = normalize(mat3(matWorld)*vNorm);

	gl_Position = merge_viewProj * vWorldPos;

	worldPos = vWorldPos.xyz;
	worldNormal = vNorm;
	texCoord = vec2(inTexCoord.x, inTexCoord.y);
	useOverlayColorReplaceMode = multiCalColor.a;

	SHADOW_VS(vec4(vPos, 1.0));
	FOG_VS(vWorldPos);
}
