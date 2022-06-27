#version 300 es
precision mediump float;


#include "headers/math/matrix.glsl"												// 教程版会用到
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#include "headers/basic.glsl"
#ifdef BUMP
#include "headers/bump.glsl"
#endif



uniform vec4 naturalColor;
uniform vec4 customColor;
uniform vec4 alphaColor;
uniform mediump float useSpecular;

uniform float discardAlpha;

#ifndef TRANSPARENT
uniform mediump vec4 multiCalColor;
#endif

in vec4 color;

in float useOverlayColorReplaceMode;
#ifdef ALPHATEST
in float vDiscardAlpha;
#endif

#if defined(LIGHT_LOW_STATIC_SKINNED) || defined(LOWEFFECT)
in vec3 lightFactor;
#endif

out vec4 fragColor;

in mediump vec4 oFogColor;

uniform vec4 fogParam[3];
mediump float LinearizeDepth(mediump float depth, mediump float near, mediump float far) 
{
    mediump float z = depth * 2.0 - 1.0; // back to NDC 
    return (2.0 * near * far) / (far + near - z * (far - near));    
}

mediump float ComputeFog(mediump float z, mediump float w, mediump float density, mediump float near, mediump float far, mediump float min, mediump vec4 notUse)
{
	const mediump float LOG2 = 1.442695;
	mediump float fogFactor = exp2(-density * density * (z / w) * (z / w) * LOG2);
	fogFactor = clamp(fogFactor, 0.0, 1.0) + 1.0 - LinearizeDepth(z, near, far) / far;
	return clamp(fogFactor, min, 1.0);
}

vec4 getLightMap() 
{
	return vec4(0.0);
}


void main(void)
{
	mediump vec4 textureColor = texture(texSampler, texCoord);
    vec2 uvOffset = vec2(0.0, 0.0);
    
#ifndef ALPHATEST
	if(textureColor.a < 0.3)
	{
		textureColor = textureColor * (1.0 - customColor.w) + customColor * customColor.w;
		textureColor.w = 1.0;
	}
#else
    if(textureColor.a < vDiscardAlpha)
    {
        discard;
    }
#endif
mediump vec4 finalColor;
 float temp = step(0.3, textureColor.a);

	vec3 normalW;
    
#ifdef BUMP
	normalW = normalize(worldNormal);
	float normalScale = vBumpInfos.y;
	mat3 TBN = cotangent_frame(normalW * normalScale, worldPos.xyz, texCoord);
	normalW = perturbNormal(TBN, texCoord + uvOffset);
#else
	normalW = worldNormal;
#endif


#ifndef ALPHATEST
    #ifndef LOWEFFECT       
        textureColor = mix(vec4(mix(textureColor.rgb, customColor.rgb, customColor.w), 1.0), textureColor, temp);
        textureColor = vec4(mix(textureColor.rgb * multiCalColor.rgb, multiCalColor.rgb, multiCalColor.a), textureColor.a);
        vec3 pixelColor = CalcPixelLight(vec3(normalW), vec3(worldPos), textureColor);
	    finalColor = vec4(pixelColor, 1.0);
        // finalColor = vec4(normalW.xyz, 1.0);
        // finalColor = vec4(worldNormal, 1.0);
        // finalColor = vec4(texture(bumpSampler, texCoord).xyz, 1.0);
        
    #else
        #ifdef TRANSPARENT
            // mediump float temp = step(0.3, textureColor.a);
            textureColor.a = temp * textureColor.a + (1.0 - temp) * 1.0;
            finalColor = (1.0 - useOverlayColorReplaceMode) * textureColor * color + useOverlayColorReplaceMode * color;
        #else
            // float temp = step(0.3, textureColor.a);
            textureColor = mix(vec4(mix(textureColor.rgb, customColor.rgb, customColor.w), 1.0), textureColor, temp);

            finalColor = vec4(mix(textureColor.rgb * multiCalColor.rgb, multiCalColor.rgb, multiCalColor.a), textureColor.a);
            
            #ifdef LIGHT_LOW_STATIC_SKINNED
                finalColor.rgb *= lightFactor;
            #endif
        #endif
    #endif
#else
    finalColor = textureColor * color;
    finalColor = alphaColor.a;
    if(useShadow > 0.0 || useSpecular > 0.0)
	{
	    mediump float shadow = useShadow > 0.0 ? getShadow() : 0.0;
	    finalColor.rgb *= clamp((1.0-shadow), 0.0, 1.0);
	}
#endif

#ifndef USEFOG
    fragColor = finalColor;
#else
	mediump vec4 oFogColor =  vec4(fogParam[1].rgb, ComputeFog(gl_FragCoord.z, gl_FragCoord.w, fogParam[0].z, fogParam[0].x, fogParam[0].y, fogParam[0].w, fogParam[2]));
    fragColor = vec4(mix(oFogColor.rgb, finalColor.rgb, oFogColor.a), finalColor.a);
#endif
}
