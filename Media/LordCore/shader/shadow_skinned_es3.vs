#version 300 es

#define MAX_BONE_NUM 73

layout(location = 0) in highp vec4 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTexCoord;
layout(location = 3) in vec4 inBlendIndices;
layout(location = 4) in vec3 inBlendWeights;

uniform highp mat4 matWVP;
uniform vec4 boneMatRows[3*MAX_BONE_NUM];

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

	gl_Position = matWVP * vec4(vPos, 1.0);

}

