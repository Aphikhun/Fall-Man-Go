#version 300 es

precision mediump float;

uniform sampler2D texGNormalRough;
uniform sampler2D texGAlbedoMetal;
uniform sampler2D texGDepth;
uniform sampler2D texSSAO;

uniform mat4 inverseVPMatrix;

out vec4 fragColor;

#include "headers/defer_lighting.glsl"
#include "headers/defer_debug.glsl"
#include "headers/fog.glsl"

vec4 calcWorldPos(vec2 coords)
{
    float depth = texture(texGDepth, coords).x;
    vec4 pos = vec4(coords.x * 2.0 - 1.0, coords.y * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
 
    vec4 WorldPos = inverseVPMatrix * pos;
    WorldPos.xyz /= WorldPos.w;
    return WorldPos;
}

void main()
{
    vec4 gPosition = calcWorldPos(texCoord);
    vec4 normalRough = texture(texGNormalRough, texCoord);
    vec3 gNormal = normalRough.rgb;
    float roughness = normalRough.a;
	vec4 albedoMetal = texture(texGAlbedoMetal, texCoord);
    vec3 gDiffuse = albedoMetal.rgb;
    float metalness = albedoMetal.a;
    float AmbientOcclusion = CalcAmbientOcclusion(texCoord);

    // calc light from gbuffer
	vec3 color = DeferredLighting(gPosition, gNormal, gDiffuse, roughness, metalness, AmbientOcclusion);

    // fog
    //mediump vec4 oFogColor = CalcFogColor();

	//color = mix(oFogColor.rgb, color, oFogColor.a);

    // 4 quad debugging
    color = DebugTo4Quad(color, gPosition.xyz, gNormal, gDiffuse);

	fragColor = vec4(color, 1.0);
}
