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
uniform mediump vec4 multiCalColor;
uniform vec4 ambient;
uniform vec4 boneMatRows[3*MAX_BONE_NUM];
uniform mat4 lightSpaceMatrix;
uniform vec3 viewPos;

uniform float useSpecular;
uniform vec4 specularColor;
uniform float specularCoef;
uniform float specularStrength;

varying vec4 color;
varying vec2 texCoord;
varying vec3 normal;
varying vec3 viewDir;
varying vec4 FragPosLightSpace;
varying vec3 vMainLightDir;
varying vec4 vMainLightColor;

varying vec4 vSpecularColor;
varying vec4 uSpecularColor;
varying float useOverlayColorReplaceMode;

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
	// blend vertex position & normal
	
	vWorldPos = matWorld * vec4(vPos, 1.0);
	
	gl_Position = matWVP * vec4(vPos, 1.0);
	texCoord = inTexCoord;
	
	vNorm = normalize(mat3(matWorld)*vNorm);
	
	float mainParam = max(dot(mainLightDir, vNorm), 0.0);
	float subParam = max(dot(subLightDir, vNorm), 0.0);
	
	normal = vNorm;
	viewDir = viewPos - vWorldPos.xyz;

	color = mainParam * mainLightColor + subParam * subLightColor + ambient;
	color.a = 1.0;
	color.rgb = color.rgb * multiCalColor.rgb;

#ifndef NEW_FOG
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif

	FragPosLightSpace = lightSpaceMatrix * vWorldPos;
	vMainLightDir = mainLightDir;
	vMainLightColor = mainLightColor;

	uSpecularColor = specularColor;
	vSpecularColor = vec4(0.0, 0.0, 0.0, 1.0);
	if(useSpecular > 0.0)
	{
		//specular
		//mediump float Gloss = 16.65;
		mediump float Gloss = specularCoef * 128.0;
		mediump vec3 nViewDir = normalize(viewDir);
		//Blinn-Phong
		mediump vec3 halfDir = normalize(vMainLightDir + nViewDir);
		mediump float spec = pow(max(dot(normal, halfDir), 0.0), Gloss);
		vSpecularColor.rgb = specularStrength * useSpecular * 2.45 * spec * vMainLightColor.rgb * specularColor.rgb;
	}
	
	useOverlayColorReplaceMode = multiCalColor.a;
}
