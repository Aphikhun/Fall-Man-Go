#version 100

#define MAX_BONE_NUM 73

attribute highp vec4 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;
attribute vec4 inBlendIndices;
attribute vec3 inBlendWeights;

uniform mat4 matWVP;
uniform mat4 matWorld;
uniform vec4 boneMatRows[3*MAX_BONE_NUM];
uniform mediump vec4 multiCalColor;
uniform vec3 viewPos;

varying vec4 color;
varying vec2 texCoord;
varying vec3 normal;
varying vec3 viewDir;

invariant gl_Position;

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

	vWorldPos = matWorld * vec4(vPos, 1.0);

	gl_Position = matWVP * vec4(vPos, 1.0);
	texCoord = inTexCoord;

	vNorm = normalize(mat3(matWorld)*vNorm);

	normal = vNorm;
	viewDir = viewPos - vWorldPos.xyz;

	color = multiCalColor;
	color.a = 1.0;

#ifndef NEW_FOG
	oFogColor = vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif
}
