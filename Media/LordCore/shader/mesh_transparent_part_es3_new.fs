#version 300 es
precision mediump float;

#include "headers/math/matrix.glsl"												// 教程版会用到
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#ifdef USEFOG
#include "headers/fog.glsl"
#endif

#ifdef BUMP
#include "headers/bump.glsl"
#endif

uniform float discardAlpha;
uniform int useOriginalcolor;
uniform vec4 naturalColor;
uniform vec4 customColor;
uniform int isUiActor;
uniform int useEdge;
uniform vec4 edgeColor;


////////////////////////////////////////////////////
//part的参�
uniform mediump vec3 uvParam;
uniform mediump float alpha;
uniform mediump float subMeshAlpha;
uniform mediump vec4 subMeshColor;
uniform mediump vec3 subMeshUVParam;
uniform mediump vec3 subMeshOffsetParam;
uniform mediump float isSubMesh;
uniform mediump float customThreshold;
uniform mediump vec4 multiCalColor;
uniform mediump float useTextureAlpha;
#ifdef INSTANCE
uniform mediump float useGPUInstance;
in mediump vec4 gpuinstanceColor;
#endif
////////////////////////////////////////////////////



float m_useOverlayColorReplaceMode;
int m_useReflect;
int m_useReflectMaskTexture;
float m_reflectMask;
int m_useOriginalcolor;
int m_useEdge;


#ifndef LOWEFFECT
	in vec2 lightMapUV;
	#ifndef NEWLIGHT
		in vec3 lightFactor;
		uniform mediump float lightMapIntensity;
	#endif
#else
	in vec3 lightFactor;
	uniform mediump float lightMapIntensity;
#ifdef STATICPART
	in vec2 lightMapUV;
#endif
#endif

#ifdef USEBATCH
in vec3 texCoordLightMap;
in vec3 texCoordBatch1;
in vec3 texCoordBatch2;

vec2 modUV(vec2 uv)
{
	float u = (uv.x > 1.0 || uv.x < -1.0) ? mod(uv.x, 1.0) : uv.x;
	float v = (uv.y > 1.0 || uv.y < -1.0) ? mod(uv.y, 1.0) : uv.y;
	u = clamp(u, 0.0, 1.0);
	v = clamp(v, 0.0, 1.0);
	return vec2(u, v);
}

#endif

uniform sampler2D lightMap;
uniform mediump vec2 bakeScale;
uniform mediump vec2 bakeOffset;

mediump vec4 getLightMap()
{
#ifndef USEBATCH
	mediump vec2 uv = lightMapUV * bakeScale + bakeOffset;
	return vec4(texture(lightMap, uv).rgba);
#else
	return texture(lightMap, texCoordLightMap.xy) * texCoordLightMap.z;
#endif
}

out vec4 fragColor;

void main(void)
{
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
#ifdef USEBATCH
	mediump float fSubMesh = 0.0;
	mediump vec2 coord = vec2(texCoord);
#else
	mediump float fSubMesh = step(0.0, isSubMesh);
	mediump vec2 coord = (1.0 - fSubMesh) * (texCoord * uvParam.xy) + fSubMesh * ((texCoord + subMeshOffsetParam.xy) * subMeshUVParam.xy);
#endif
	
	mediump vec4 color = vec4(multiCalColor.rgb, 1.0);
	mediump float useOverlayColorReplaceMode = multiCalColor.a;

#ifdef USEBATCH
	vec2 bigUV = modUV(coord);
	bigUV.x = mix(texCoordBatch1.x, texCoordBatch2.x, bigUV.x);
	bigUV.y = mix(texCoordBatch1.y, texCoordBatch2.y, bigUV.y);
	coord = bigUV;
#endif

	mediump vec4 textureColor = texture(texSampler, coord);
	mediump float textureAlpha = textureColor.a;
	vec4 finalColor; 
	if(useTextureAlpha > 0.0)
	{
		if (textureColor.a < discardAlpha)
		{
			discard;
		}

#ifdef INSTANCE
		mediump vec4 realColor = (useGPUInstance > 0.9 ? gpuinstanceColor : customColor);
#endif
		mediump float fAlpha = step(textureColor.a, 0.3);
		textureColor.rgb = (1.0 - fAlpha) * textureColor.rgb + fAlpha * (textureColor.rgb * (1.0 - customColor.a) + customColor.rgb * customColor.a);
		textureColor.a = (1.0 - fAlpha) * textureColor.a + fAlpha;

		finalColor = (1.0 - useOverlayColorReplaceMode) * textureColor * color + useOverlayColorReplaceMode * color;
		mediump float fNature = dot(max(sign(vec3(1.0) - naturalColor.rgb), 0.0), vec3(1.0));
		fNature = sign(fNature);
		textureColor.a = (1.0 - fNature) * textureColor.a + fNature * (finalColor.r * 0.299 + finalColor.g * 0.587 + finalColor.b * 0.114);
		finalColor = (1.0 - fNature) * finalColor + fNature * naturalColor * textureColor.a;

		finalColor.a *= (1.0 - fSubMesh) * alpha + fSubMesh * subMeshAlpha;

		mediump vec4 c0 = vec4(textureColor.rgb * customColor.rgb, finalColor.a);
		mediump vec4 c1 = vec4(textureColor.rgb, finalColor.a);
		mediump vec4 c2 = vec4(textureColor.rgb * subMeshColor.rgb, finalColor.a);
		mediump float fCustom = step(textureAlpha, customThreshold);
		finalColor = fCustom * c0 + (1.0 - fCustom) * c1;
		finalColor = (1.0 - fSubMesh) * finalColor + fSubMesh * c2;
		// finalColor = vec4(1.0, 0.0, 0.0, finalColor.a);
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	}
	else 
	{
		textureColor.a = 1.0;
		finalColor = (1.0 - useOverlayColorReplaceMode) * textureColor * color + useOverlayColorReplaceMode * color;
		float fNature = dot(max(sign(vec3(1.0) - naturalColor.rgb), vec3(0.0)), vec3(1.0));
		fNature = sign(fNature);
		textureColor.a = (1.0 - fNature) * textureColor.a + fNature * (finalColor.r * 0.299 + finalColor.g * 0.587 + finalColor.b * 0.114);
		float finalAlpha = (1.0 - fNature) * finalColor.a;
		finalAlpha += fNature * textureColor.a * naturalColor.a;
		finalAlpha *= (1.0 - fSubMesh) * alpha + fSubMesh * subMeshAlpha; 
		finalColor.rgb = textureColor.rgb;
		finalColor.a = finalAlpha;
		// finalColor = vec4(0.0, 1.0, 0.0, finalAlpha);
	}

	// vec3 vNormalW = worldNormal;
	vec3 normalW;
#ifdef BUMP
	normalW = normalize(worldNormal);
	vec2 uvOffset = vec2(0.0, 0.0);
	float normalScale = vBumpInfos.y;
	mat3 TBN = cotangent_frame(normalW * normalScale, worldPos.xyz, coord);
	normalW = perturbNormal(TBN, coord + uvOffset);
#else
	normalW = worldNormal;
#endif

#ifndef LOWEFFECT
	// vec3 pixelColor = CalcPixelLight(vec3(normalW), vec3(worldPos), finalColor);
	vec3 pixelColor;
	#ifdef NEWLIGHT
		pixelColor = CalcPixelLight(vec3(normalW), vec3(worldPos), finalColor);
	#else
		pixelColor = lightFactor * finalColor.rgb;
		mediump vec4 pointLightMap = getLightMap();
		mediump vec3 bakeLightColor = pixelColor.rgb * pointLightMap.rgb * lightMapIntensity;
		pixelColor.rgb += bakeLightColor;
	#endif
	#ifndef USEFOG
		fragColor = vec4(pixelColor, alpha * textureColor.a);
	#else
		mediump vec4 oFogColor = CalcFogColor();
		fragColor = vec4(mix(oFogColor.rgb, pixelColor, oFogColor.a), alpha * textureColor.a);
	#endif
#else
  	mediump vec3 result = lightFactor * finalColor.rgb;
	mediump vec4 pointLightMap = getLightMap();
	result.rgb += (result.rgb * pointLightMap.rgb * lightMapIntensity);
	
	#ifndef USEFOG
		fragColor = vec4(result, alpha * finalColor.a);
	#else
		mediump vec4 oFogColor = CalcFogColor();
		fragColor = vec4(mix(oFogColor.rgb, result, oFogColor.a), alpha * finalColor.a);
	#endif
#endif // LOWEFFECT

//mesh_transparent_part_es3_new.fs
}
