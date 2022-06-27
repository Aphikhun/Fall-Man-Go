#version 100

#define MAX_BONE_NUM 73

attribute highp vec4 inPosition;
attribute vec3 inNormal;
attribute vec3 inTexCoord;
attribute vec4 inBlendIndices;
attribute vec3 inBlendWeights;

uniform mat4 matVP;
uniform vec4 boneMatRows[3*MAX_BONE_NUM];
uniform mat4 mergeWorldProj[20];

invariant gl_Position;

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
	
  	vec3 vPos = MulBone4(inPosition, BoneIndices.x, inBlendWeights.x)
  	 + MulBone4(inPosition, BoneIndices.y, inBlendWeights.y)
  	 + MulBone4(inPosition, BoneIndices.z, inBlendWeights.z);

	int matIndex = int(inTexCoord.z);
    mat4 curMatWorld = mergeWorldProj[matIndex];

	gl_Position = matVP * curMatWorld * vec4(vPos, 1.0);

}

