#version 300 es
precision mediump float;

#define LOWEFFECT
#define USEFOG
#define TRANSPARENT

#include "headers/basic.glsl"
#include "headers/lighting.glsl"
#include "headers/fog.glsl"
#ifndef LOWEFFECT
#include "headers/shadow.glsl"
#endif

#ifdef BUMP
#include "headers/bump.glsl"
#endif

uniform mediump vec4 multiCalColor;
uniform vec4 customColor;
uniform mediump discardAlpha;

#ifdef LOWEFFECT
in vec4 color; 
in float useOverlayColorReplaceMode;
#endif

#ifdef LIGHT_LOW_STATIC_SKINNED
int vec3 lightFactor;
#endif

out vec4 fragColor;

vec4 getLightMap() 
{
	return vec4(0.0);
}

void main(void)
{
	vec4 textureColor = texture(texSampler, texCoord);

	float temp = step(0.3, textureColor.a);
	textureColor = mix(vec4(mix(textureColor.rgb, customColor.rgb, customColor.w), 1.0), textureColor, temp);
	textureColor = vec4(mix(textureColor.rgb * multiCalColor.rgb, multiCalColor.rgb, multiCalColor.a), textureColor.a);

    vec4 finalColor;

vec3 normalW;
#ifdef BUMP
	normalW = normalize(worldNormal);
	vec2 uvOffset = vec2(0.0, 0.0);
	float normalScale = vBumpInfos.y;
	mat3 TBN = cotangent_frame(normalW * normalScale, worldPos.xyz, texCoord);
	normalW = perturbNormal(TBN, texCoord + uvOffset);
#else
	normalW = worldNormal;
#endif

#ifndef LOWEFFECT
	vec3 pixelColor = CalcPixelLight(vec3(normalW), vec3(worldPos), textureColor);

	finalColor = vec4(pixelColor, 1.0);
#else
#ifndef TRANSPARENT
    finalColor = (1.0 - useOverlayColorReplaceMode) * textureColor * color + useOverlayColorReplaceMode * color;
#else
    finalColor = vec4(mix(textureColor.rgb * multiCalColor.rgb, multiCalColor.rgb, multiCalColor.a), textureColor.a);
#endif
#endif

#ifdef LIGHT_LOW_STATIC_SKINNED
    finalColor.rgb *= lightFactor;
#endif

#ifndef USEFOG
	mediump vec4 oFogColor = CalcFogColor();

	fragColor = vec4(mix(oFogColor.rgb, finalColor.rgb, oFogColor.a), finalColor.a);
#else
    fragColor = finalColor;
#endif
}

