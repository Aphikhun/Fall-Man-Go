#version 300 es

[VS]
#pragma oncein

#define MAX_BONE_NUM 73

in vec3 inBlendWeights;
in vec4 inBlendIndices;

uniform vec4 boneMatRows[3*MAX_BONE_NUM];

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

vec3 GetSkinnedPos()
{
	ivec3 BoneIndices;
	BoneIndices.x = int(inBlendIndices.x);
	BoneIndices.y = int(inBlendIndices.y);
	BoneIndices.z = int(inBlendIndices.z);
	
  	return MulBone4(inPosition, BoneIndices.x, inBlendWeights.x)
	     + MulBone4(inPosition, BoneIndices.y, inBlendWeights.y)
	     + MulBone4(inPosition, BoneIndices.z, inBlendWeights.z);
}

vec3 GetSkinnedNormal()
{
	ivec3 BoneIndices;
	BoneIndices.x = int(inBlendIndices.x);
	BoneIndices.y = int(inBlendIndices.y);
	BoneIndices.z = int(inBlendIndices.z);
	
	return MulBone3(inNormal, BoneIndices.x, inBlendWeights.x)
         + MulBone3(inNormal, BoneIndices.y, inBlendWeights.y)
         + MulBone3(inNormal, BoneIndices.z, inBlendWeights.z);
	// blend vertex position & normal
}

[PS]
#pragma once
