#version 300 es

precision mediump float;

#include "headers/basic.glsl"
#include "headers/lighting.glsl"

uniform sampler2D depthTexture;
uniform float depthTextureSize;
uniform vec3 lightDir;

out vec4 fragColor;

vec4 getLightMap()
{
    return vec4(0.0);
}

void main(void)
{
    vec3 norm = normalize(worldNormal);//todo.shader:去掉这两处normalize
    vec3 viewDir = normalize(viewPos - worldPos);

    vec4 projCoords = FragPosLightSpace / FragPosLightSpace.w;
    projCoords = projCoords * 0.5 + 0.5;

    float currentDepth = projCoords.z;

	float outSize = 1.0 - max(sign(1.0 - projCoords.x), 0.0) 
        + 1.0 - max(sign(projCoords.x - 0.0), 0.0) 
        + 1.0 - max(sign(1.0 - projCoords.y), 0.0) 
        + 1.0 - max(sign(projCoords.y - 0.0), 0.0)
        + max(sign(projCoords.z - 1.0), 0.0);
  
	if (outSize > 0.0)
		outSize = 0.0;
	else
		outSize = 1.0;

    float diff = max(dot(norm, normalize(lightDir)), 0.0);
    float bias = mix(0.02, 0.001, diff);
    bias = 0.00132;
    float shadow = 0.0;
    vec2 pixelSize = vec2(1.0 / depthTextureSize);
    const int iter = 5;
    for(int x = -iter; x <= iter; x++)
	{
        for(int y= -iter; y <= iter; y++)
		{
            float closestDepth = texture(depthTexture, vec2(projCoords.xy + vec2(x, y) * pixelSize)).r;
            shadow += (1.0 - step(currentDepth - bias, closestDepth));
        }
    }

    float coreSize = pow(2.0 * float(iter) + 1.0, 2.0);
    shadow /= coreSize;

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
		mediump float closestDepth = texture(depthTexture, projCoords.xy + poissonDisk[index] / depthTextureSize ).r;
		shadow += 0.2 * (1.0 - step(currentDepth - bias, closestDepth));
	}


	shadow = clamp(shadow, 0.0, 1.0); 

	//float closestDepth = texture(depthTexture, projCoords.xy).r;
	//shadow = (1.0 - step(currentDepth - 0.00132, closestDepth));

    vec3 pixelColor = vec3(0);
    for(int i = 0; i < NR_POINT_LIGHTS; i++)
	    pixelColor += CalcBakePointLight(pointLights[i], norm, worldPos, viewDir, material.roughness, material.metalness);

    for(int i = 0; i < NR_SPOT_LIGHTS; i++)
	    pixelColor += CalcBakeSpotLight(spotLights[i], norm, worldPos, viewDir, material.metalness);

	fragColor = vec4(pixelColor, shadow * outSize);
	//fragColor = vec4(vec3(shadow * outSize), 1.0);
}
