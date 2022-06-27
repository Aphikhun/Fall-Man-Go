#version 300 es

[VS]
#pragma once

#ifdef USE_SHADOW_CSM

out vec4 position;

#define SHADOW_VS(pos)  position = matWorld * pos;

#else

uniform mediump mat4 lightSpaceMatrix[4];

out vec4 FragPosLightSpace;

#define SHADOW_VS(pos) FragPosLightSpace = lightSpaceMatrix[0] * matWorld * pos;

#endif

[PS]
#pragma once


uniform float useShadow;
uniform float imageSize;

uniform float shadowIntensity;
uniform mat4 lightSpaceMatrix[4];

#ifdef USE_SHADOW_CSM

// #extension GL_EXT_texture_array : enable

uniform mediump sampler2DArray texSamplerMapArray;
uniform vec4 farBounds;

in vec4 position;

mediump float getShadowByWorldPos(vec4 worldPos, float diff)
{
	int index = 3;
  	// find the appropriate depth map to look up in based on the depth of this fragment
  	if(gl_FragCoord.z < farBounds.x) 
	{
    	index = 0;
  	}
	else if(gl_FragCoord.z < farBounds.y) 
	{
    	index = 1;
  	}
	else if(gl_FragCoord.z < farBounds.z)
	{
    	index = 2;
  	}

	vec4 FragPosLightSpace = lightSpaceMatrix[index] * worldPos;

	vec3 projCoords = FragPosLightSpace.xyz / FragPosLightSpace.w;
    projCoords = projCoords * 0.5 + 0.5;

    mediump float tmp = 1.0 - max(sign(1.0 - projCoords.x), 0.0) 
            + 1.0 - max(sign(projCoords.x - 0.0), 0.0) 
            + 1.0 - max(sign(1.0 - projCoords.y), 0.0) 
            + 1.0 - max(sign(projCoords.y - 0.0), 0.0)
            + max(sign(projCoords.z - 1.0), 0.0)
            + 1.0 - sign(useShadow);
  
	if(tmp > 0.0) return 0.0;  

    float closestDepth = texture(texSamplerMapArray, vec3(projCoords.xy, float(index))).r;
    float currentDepth = projCoords.z;
    float bias = mix(0.02, 0.001, diff);
    
    float shadow = 0.0f;
    vec2 pixelSize = vec2(1.0 / imageSize);
    for(int x = -1; x <= 1; x++)
	{
        for(int y= -1; y <= 1; y++)
		{
            float closestDepth = texture(texSamplerMapArray, vec3(projCoords.xy + vec2(x, y) * pixelSize, float(index))).r;
            shadow += 1.0 * (1.0 - step(currentDepth - bias, closestDepth));
        }
    }

    shadow /= 9.0f;
	shadow *= shadowIntensity;
	return shadow;
}

mediump float getShadow(float diff)
{
    float shadow = getShadowByWorldPos(position, diff) * step(0.0, useShadow);
	return clamp((1.0-shadow), 0.0, 1.0);
}

mediump float CalcShadow(vec4 worldPos, float diff)
{
	worldPos.xyz *= worldPos.w;
    float shadow = getShadowByWorldPos(worldPos, diff) * step(0.0, useShadow);
	return clamp((1.0-shadow), 0.0, 1.0);
}

#else

uniform sampler2D texSampler_depthmap;

in vec4 FragPosLightSpace;

// #define USE_SHADOW_PCF_POISSON // program injection 

// Returns a random number based on a vec3 and an int.
mediump float random(mediump vec3 seed, mediump int i)
{
	mediump vec4 seed4 = vec4(seed, i);
	mediump float dot_product = dot(seed4, vec4(12.9898,78.233,45.164,94.673));
	return fract(sin(dot_product) * 43758.5453);
}

mediump float getShadowByLightSpacePos(vec4 fragPosLightSpace, float diff)
{
	mediump float closestDepth = 0.0;

    mediump float currentDepth = 0.0;
    mediump vec3 projCoords;
    mediump vec4 depthColor;
    mediump float shadow = 0.0;

    projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    projCoords = projCoords * 0.5 + 0.5;

    mediump float tmp = 1.0 - max(sign(1.0 - projCoords.x), 0.0) 
            + 1.0 - max(sign(projCoords.x - 0.0), 0.0) 
            + 1.0 - max(sign(1.0 - projCoords.y), 0.0) 
            + 1.0 - max(sign(projCoords.y - 0.0), 0.0)
            + max(sign(projCoords.z - 1.0), 0.0)
            + 1.0 - sign(useShadow);
  
	if(tmp > 0.0) return 0.0;  

	currentDepth = projCoords.z;

	mediump float bias = mix(useShadow, 0.001, diff);

#if defined (USE_SHADOW_PCF)
	// PCF 高斯模糊
	mediump vec2 pixelSize = vec2(1.0 / imageSize);
    mediump float shadowWeights[9];
    shadowWeights[0] = shadowWeights[2] = shadowWeights[6] = shadowWeights[8] = 0.0947416;
    shadowWeights[1] = shadowWeights[3] = shadowWeights[5] = shadowWeights[7] = 0.118318;
    shadowWeights[4] = 0.1477616;
    lowp int wi = 0;
	for (lowp int i = -1; i <= 1; ++i)
	{
		for (lowp int j = -1; j <= 1; ++j)
		{
			depthColor = texture(texSampler_depthmap, projCoords.xy + pixelSize * vec2(i, j));
			closestDepth = depthColor.r;
			mediump float s = (1.0 - step(currentDepth - bias, closestDepth));
            shadow += s * shadowWeights[wi];
            wi = wi + 1;
		}
		shadow *= shadowIntensity; 
	}

#elif defined (USE_SHADOW_PCF_POISSON)
	// PCF 泊松分布 http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-16-shadow-mapping/
	mediump vec2 poissonDisk[16];
  	poissonDisk[0] = vec2( -0.94201624, -0.39906216 );
  	poissonDisk[1] = vec2( 0.94558609, -0.76890725 );
  	poissonDisk[2] = vec2( -0.094184101, -0.92938870 );
  	poissonDisk[3] = vec2( 0.34495938, 0.29387760 );
	poissonDisk[4] = vec2( -0.91588581, 0.45771432 );
  	poissonDisk[5] = vec2( -0.81544232, -0.87912464 );
  	poissonDisk[6] = vec2( -0.38277543, 0.27676845 );
  	poissonDisk[7] = vec2( 0.97484398, 0.75648379 );
	poissonDisk[8] = vec2( 0.44323325, -0.97511554 );
  	poissonDisk[9] = vec2( 0.53742981, -0.47373420 );
  	poissonDisk[10] = vec2( -0.26496911, -0.41893023 );
  	poissonDisk[11] = vec2( 0.79197514, 0.19090188 );
	poissonDisk[12] = vec2( -0.24188840, 0.99706507 );
  	poissonDisk[13] = vec2( -0.81409955, 0.91437590 );
  	poissonDisk[14] = vec2( 0.19984126, 0.78641367 );
  	poissonDisk[15] = vec2( 0.14383161, -0.14100790 );

	for (mediump int i = 0; i < 4; i++)
	{
		//mediump int index = i; // 泊松分布
		mediump int index = int(mod(float(16.0 * random(gl_FragCoord.xyy, i)), 16.0)); // 引入随机，分层泊松分布
		mediump float closestDepth = texture(texSampler_depthmap, projCoords.xy + poissonDisk[index] / imageSize ).r;
		shadow += 0.2 * (1.0 - step(currentDepth - bias, closestDepth));
	}
	shadow *= shadowIntensity; 

#else

	depthColor = texture(texSampler_depthmap, projCoords.xy);
	closestDepth = depthColor.r;
	shadow = (1.0 - step(currentDepth - bias, closestDepth)) * shadowIntensity;

#endif

    mediump float d = distance(projCoords.xy, vec2(0.5, 0.5)) - 0.4;
    d = clamp(d, 0.0, 0.1);
    shadow = mix(shadow, 0.0, d * 10.0);

    return shadow;
}

mediump float getShadow(float diff)
{
    float shadow = getShadowByLightSpacePos(FragPosLightSpace, diff) * step(0.0, useShadow);
	return clamp(shadow, 0.0, 1.0);
}

mediump float CalcShadow(vec4 worldPos, float diff)
{
	worldPos.xyz *= worldPos.w;
    vec4 fragPosLightSpace = lightSpaceMatrix[0] * worldPos;
    float shadow = getShadowByLightSpacePos(fragPosLightSpace, diff) * step(0.0, useShadow);
	return clamp((1.0-shadow), 0.0, 1.0);
}
#endif
