#version 100

#define MAX_BONE_NUM 73

attribute highp vec4 inPosition;
attribute vec3 inTexCoord;
attribute vec4 inBlendIndices;
attribute vec3 inBlendWeights;

uniform mat4 matWVP;
uniform vec4 boneMatRows[3*MAX_BONE_NUM];

uniform mat4 merge_worldProj[20];
uniform mat4 merge_viewProj;

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
	ivec3 BoneIndices;
	BoneIndices.x = int(inBlendIndices.x);
	BoneIndices.y = int(inBlendIndices.y);
	BoneIndices.z = int(inBlendIndices.z);

	vec3 vPos;
	vPos  = MulBone4(inPosition, BoneIndices.x, inBlendWeights.x);
	vPos += MulBone4(inPosition, BoneIndices.y, inBlendWeights.y);
	vPos += MulBone4(inPosition, BoneIndices.z, inBlendWeights.z);

	int meshIndexi = int(inTexCoord.z);
	mat4 curMatWorld = merge_worldProj[meshIndexi];

	gl_Position = merge_viewProj * curMatWorld * vec4(vPos, 1.0);
}