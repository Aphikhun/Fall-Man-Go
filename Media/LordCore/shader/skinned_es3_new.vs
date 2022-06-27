#version 300 es
precision mediump float;

#define LOWEFFECT
#define USEFOG
#define TRANSPARENT


#include "headers/basic.glsl"
#include "headers/math/matrix.glsl"													// 教程版会用到
#include "headers/skinned.glsl"
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#ifdef USEFOG
#include "headers/fog.glsl"
#endif


#if defined(LOWEFFECT) && defined(TRANSPARENT)
uniform vec4 multiCalColor;
uniform vec4 alphaColor;
out vec4 color; 
out float useOverlayColorReplaceMode;
#endif



void main(void)
{
    vec3 skinnedPos = GetSkinnedPos();
	vec3 skinnedNormal = GetSkinnedNormal();

	worldPos = vec3(matWorld * vec4(skinnedPos, 1.0));

	worldNormal = normalize(mat3(matWorld) * skinnedNormal);						// 	
	texCoord = inTexCoord;

	gl_Position = matWVP * vec4(skinnedPos, 1.0);

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	vec4 vWorldPos = matWorld * vec4(skinnedPos, 1.0);

#if LOWEFFECT && defined(TRANSPARENT)
    color = multiCalColor;
    color.a = alphaColor;
    color.a += inNormal.x*0.00001;
	
#else
	SHADOW_VS(vec4(skinnedPos, 1.0));
#endif

	FOG_VS(vWorldPos);

    useOverlayColorReplaceMode = multiCalColor.a;
}