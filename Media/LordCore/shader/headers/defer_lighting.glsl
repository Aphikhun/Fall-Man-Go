#version 300 es

[VS]
#pragma once

[PS]
#pragma once

#include "headers/basic.glsl" // pragma once测试，所有被include的路径名都必须从shader根目录开始算
#include "headers/shadow.glsl"
#include "headers/tone_mapping.glsl"

struct DirLight {
    vec3 direction;
	
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct PointLight {
    vec3 position;
    
    float constant;
    float linear;
    float quadratic;
	
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct SpotLight {
    vec3 position;
    vec3 direction;
    float cutOff;
    float outerCutOff;
  
    float constant;
    float linear;
    float quadratic;
  
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;       
};

#define NR_POINT_LIGHTS 4
#define NR_SPOT_LIGHTS  1

uniform vec3 viewPos;
uniform DirLight dirLight;
uniform PointLight pointLights[NR_POINT_LIGHTS];
uniform SpotLight spotLights[NR_SPOT_LIGHTS];
uniform int blinn;
uniform float ssaoIntensity;

#define METAL_SPEC          0.40                                    //粗糙金属高光强度，0.4
#define MAX_SHININESS       150.0                                   //高光计算shininess最大值

// calculates spec
float CalcSpec(vec3 lightDir, vec3 normal, vec3 viewDir, float gRoughness, float gMetalness)
{
    float shininess = mix(MAX_SHININESS, 1.0, gRoughness);
    float spec;
    if (blinn > 0)
    {
        vec3 halfwayDir = normalize(lightDir + viewDir);  
        spec = pow(max(dot(normal, halfwayDir), 0.0), shininess); // material.shininess=32.0
    }
    else
    {
        vec3 reflectDir = reflect(-lightDir, normal);
        spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess); // material.shininess=8.0
    }
    spec *= mix(1.0, mix(0.0, METAL_SPEC, gMetalness), gRoughness);
    return spec;
}

// calculates the color when using a directional light.
vec3 CalcDirLight(DirLight light, vec3 gNormal, vec3 viewDir, vec3 gAlbedo, float gRoughness, float gMetalness, float fShadow, float ambientOcclusion)
{
    //vec3 lightDir = normalize(-light.direction);//todo.shader:传光的反方向
    vec3 lightDir = normalize(light.direction);
    // diffuse shading
    float diff = max(dot(gNormal, lightDir), 0.0);
    // specular shading
    float spec = CalcSpec(lightDir, gNormal, viewDir, gRoughness, gMetalness);
    // combine results
    vec3 ambient = light.ambient * gAlbedo * (1.0 - gMetalness) * ambientOcclusion;
    vec3 diffuse = light.diffuse * diff * gAlbedo * (1.0 - gMetalness) * ambientOcclusion;
    vec3 specular = light.specular * spec;
    // no attenuation
    return (ambient + diffuse * fShadow + specular * fShadow);
}

// calculates the color when using a point light.
vec3 CalcPointLight(PointLight light, vec3 gNormal, vec3 gPosition, vec3 viewDir, vec3 gAlbedo, float gRoughness, float gMetalness, float fShadow)
{
    vec3 lightDir = normalize(light.position - gPosition);
    // diffuse shading
    float diff = max(dot(gNormal, lightDir), 0.0);
    // specular shading
    float spec = CalcSpec(lightDir, gNormal, viewDir, gRoughness, gMetalness);
    // attenuation
    float distance = length(light.position - gPosition);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));    
    // combine results
    vec3 ambient = light.ambient * gAlbedo * (1.0 - gMetalness);
    vec3 diffuse = light.diffuse * diff * gAlbedo * (1.0 - gMetalness);
    vec3 specular = light.specular * spec;
    // attenuation
    ambient *= attenuation;
    diffuse *= attenuation;
    specular *= attenuation;
    return (ambient + diffuse * fShadow + specular * fShadow);
}

// calculates the color when using a spot light.
vec3 CalcSpotLight(SpotLight light, vec3 gNormal, vec3 gPosition, vec3 viewDir, vec3 gAlbedo, float gRoughness, float gMetalness, float fShadow)
{
    vec3 lightDir = normalize(light.position - gPosition);
    // diffuse shading
    float diff = max(dot(gNormal, lightDir), 0.0);
    // specular shading
    float spec = CalcSpec(lightDir, gNormal, viewDir, gRoughness, gMetalness);
    // attenuation
    float distance = length(light.position - gPosition);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
    // spotlight intensity
    //float theta = dot(lightDir, normalize(-light.direction));//todo.shader:传光的反方向
    float theta = dot(lightDir, normalize(light.direction));
    float epsilon = light.cutOff - light.outerCutOff;
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);
    // combine results
    vec3 ambient = light.ambient * gAlbedo * (1.0 - gMetalness);
    vec3 diffuse = light.diffuse * diff * gAlbedo * (1.0 - gMetalness);
    vec3 specular = light.specular * spec;
    // attenuation
    ambient *= attenuation * intensity;
    diffuse *= attenuation * intensity;
    specular *= attenuation * intensity;
    return (ambient + diffuse * fShadow + specular * fShadow);
}

float CalcAmbientOcclusion(vec2 texCoord)
{
    if (ssaoIntensity > 0.0)
    {
        return texture(texSSAO, texCoord).r * ssaoIntensity;
    }
    else 
    {
        return 1.0;
    }
}

vec3 DeferredLighting(vec4 gPosition4, vec3 gNormal, vec3 gAlbedo, float gRoughness, float gMetalness, float ambientOcclusion)
{

    // properties
    vec3 gPosition = gPosition4.xyz;
    vec3 viewDir = normalize(viewPos - gPosition);

    float diff = max(dot(norm, normalize(dirLight.direction)), 0.0);
    float fShadow = CalcShadow(gPosition4, diff);
    
    // == =====================================================
    // Our lighting is set up in 3 phases: directional, point lights and an optional flashlight
    // For each phase, a calculate function is defined that calculates the corresponding color
    // per lamp. In the main() function we take all the calculated colors and sum them up for
    // this fragment's final color.
    // == =====================================================
    // phase 1: directional lighting
    vec3 hdrColor = CalcDirLight(dirLight, gNormal, viewDir, gAlbedo, gRoughness, gMetalness, fShadow, ambientOcclusion);

    // phase 2: point lights
    for(int i = 0; i < NR_POINT_LIGHTS; i++)
        hdrColor += CalcPointLight(pointLights[i], gNormal, gPosition, viewDir, gAlbedo, gRoughness, gMetalness, fShadow);

    // phase 3: spot light
    for(int i = 0; i < NR_SPOT_LIGHTS; i++)
        hdrColor += CalcSpotLight(spotLights[i], gNormal, gPosition, viewDir, gAlbedo, gRoughness, gMetalness, fShadow);

    vec3 result = toneMapping(hdrColor);
    //result = vec3(1.0, 0.0, 0.0);
    //result = gNormal;
    return result;
}
