#version 300 es

[VS]
#pragma once

// new implement
uniform vec3 viewPos;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ↓
// basic & diffuse
//uniform vec3 viewPos;
uniform vec4 ambient;
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec3 subLightDir;
uniform vec4 subLightColor;

out vec3 viewDir;
out vec3 vMainLightDir;
out vec4 vMainLightColor;

//specular
uniform float useSpecular;
uniform vec4 specularColor;
uniform float specularCoef;
uniform float specularStrength;

out vec4 vSpecularColor;
out vec4 uSpecularColor;

vec4 CalcVertexLight(vec3 worldNormal, vec4 ambient, vec3 mainLightDir, vec4 mainLightColor, vec3 subLightDir, vec4 subLightColor)
{
	float mainParam = max(dot(mainLightDir, worldNormal), 0.0);
	float subParam = max(dot(subLightDir, worldNormal), 0.0);
	vec4 color = mainParam * mainLightColor + subParam * subLightColor + ambient;
	color.a = 1.0;
	return color;
}
// ↑
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


[PS]
#pragma once
//#define TILE_TEST

#include "headers/basic.glsl" // pragma once测试，所有被include的路径名都必须从shader根目录开始算
#include "headers/material.glsl"
#include "headers/shadow.glsl"
#include "headers/tone_mapping.glsl"

struct AmbientLight {
    vec3 equatorColor;
    vec3 skyColor;
    float intensity;
};

struct DirLight {
    vec3 direction;
	vec3 color;
    float intensity;
};

struct PointLight {
    vec3 position;
    vec3 color;
    float intensity;
    float constant;
    float linear;
    float quadratic;
	
};

struct SpotLight {
    vec3 position;
    vec3 direction;
    vec3 color;
    float intensity;

    float cutOff;
    float outerCutOff;
  
    float constant;
    float linear;
    float quadratic;
    
};

struct RectangularAreaLight {
    vec3 position;
    vec3 direction;
    vec3 color;
    float intensity;

    float cutOff;
    float outerCutOff;
  
    float constant;
    float linear;
    float quadratic;

    vec2 size;
    mat4 viewMatrix;
};

#ifdef TILE_TEST
	struct TilePointLight {
	    vec4 position;
	    vec4 ambient;
	    vec4 diffuse;
	    vec4 specular;
	    float constant;
	    float linear;
	    float quadratic;
	    float _padding0;
	};
	struct TileSpotLight {
	    vec4 position;
	    vec4 direction;
	    vec4 ambient;
	    vec4 diffuse;
	    vec4 specular;
	    float cutOff;
	    float outerCutOff;
	    float constant;
	    float linear;
	    float quadratic;
	    float _padding0;
	    float _padding1;
	    float _padding2;
	};
	#define MAX_TILE_POINT_LIGHT 400
	#define MAX_TILE_SPOT_LIGHT 400
	layout (std140) uniform TilePointLightBlock {
	    TilePointLight tilePointLights[MAX_TILE_POINT_LIGHT];
	};
	layout (std140) uniform TileSpotLightBlock {
	    TileSpotLight tileSpotLights[MAX_TILE_SPOT_LIGHT];
	};
#endif

#define NR_POINT_LIGHTS 4
#define NR_SPOT_LIGHTS  1
#define NR_AREA_LIGHTS  1

uniform vec3 viewPos;
uniform float ambientStrength;
uniform AmbientLight ambientLight;
uniform DirLight dirLight;
uniform PointLight pointLights[NR_POINT_LIGHTS];
uniform SpotLight spotLights[NR_SPOT_LIGHTS];
uniform RectangularAreaLight areaLights[NR_AREA_LIGHTS];
uniform int blinn;

#define METAL_SPEC          0.40                                    //粗糙金属高光强度，0.4
#define MAX_SHININESS       150.0                                   //高光计算shininess最大值

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ↓
uniform int useReflect;
uniform float reflectScale;
uniform sampler2D texSampler_reflect;
uniform int useReflectMaskTexture;
uniform sampler2D texSampler_reflect_mask;

in vec3 viewDir;

in vec3 vMainLightDir;
in vec4 vMainLightColor;
in vec4 vSpecularColor;
in vec4 uSpecularColor;

#ifdef SPECULAR
#include "headers/specularMap.glsl"
#endif

#ifdef EMISSION
#include "headers/emission.glsl"
#endif

// ↑
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float calculateAttenuation(float dist, float constantAttenuation, float linearAttenuation, float quadraticAttenuation)
{    
    return (1.0 / (constantAttenuation + linearAttenuation * dist + quadraticAttenuation * dist * dist));
}

vec3 projectOnPlane(vec3 _point, vec3 center_of_plane, vec3 normal_of_plane)
{
    return _point - (dot(_point - center_of_plane, normal_of_plane) * normal_of_plane);
}

bool sideOfPlane(vec3 _point, vec3 center_of_plane, vec3 normal_of_plane)
{
    return dot(_point - center_of_plane, normal_of_plane) > 0.0f;
}

// calculates spec
float CalcSpec(vec3 lightDir, vec3 normal, vec3 viewDir, float roughness, float metalness)
{
    float shininess = mix(MAX_SHININESS, 1.0, roughness);
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
    spec *= mix(1.0, mix(0.0, METAL_SPEC, metalness), roughness);
    return spec;
}

vec3 CalcAmbientLight(AmbientLight light, vec3 normal, vec3 viewDir, vec3 diffuseColor, float metalness)
{
    vec3 VNreflect = (reflect(viewDir, normal));
    float VNrefY = clamp(VNreflect.y, 0.0, 1.0);
    vec3 color = mix(light.skyColor, light.equatorColor, VNrefY);
    return color * light.intensity * diffuseColor * (1.0 - metalness);
}

// calculates the color when using a directional light.
vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir, vec3 diffuseColor, float roughness, float metalness, float fShadow)
{
    //vec3 lightDir = normalize(-light.direction);//todo.shader:传光的反方向
    vec3 lightDir = normalize(light.direction);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);

    // combine results
    vec3 color = light.color * light.intensity * diff * diffuseColor * (1.0 - metalness);//material.diffuse

    ////////////////////////////////////////////////////////////////////////
    // @zizhangming: pointLight和spotLight如果也需要，也像下面这样添加两项。
    // 我暂时只加了DirLight
    // 自发光
    vec3 diffuse;
#ifdef EMISSION
    vec3 emissionColor = computeEmissiveColor(vEmissiveSampler, texCoord);
    color += emissionColor;
    color = clamp(color, 0.0, 1.0);
#endif
    // 高光
#ifdef SPECULAR
    vec4 specularMapColor = computeSpecularColor(specularSampler, texCoord);
    float spec = CalcSpec(lightDir, normal, viewDir, roughness, metalness);
    vec3 specular = light.color * spec;//material.specular
    vec3 finalSpecular = specularMapColor.xyz * specular;
    color += finalSpecular;
#endif
    ////////////////////////////////////////////////////////////////////////

    // no attenuation
    return (color * fShadow);
}

// calculates the color when using a point light.
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir, vec3 diffuseColor, float roughness, float metalness, float fShadow)
{
    vec3 lightDir = normalize(light.position - fragPos);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);
    // attenuation
    float distance = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));    
    // combine results
    vec3 color = light.color * light.intensity * diff * diffuseColor * (1.0 - metalness);//material.diffuse
    
#ifdef EMISSION
    vec3 emissionColor = computeEmissiveColor(vEmissiveSampler, texCoord);
    color += emissionColor;
    color = clamp(color, 0.0, 1.0);
#endif
    // 高光
#ifdef SPECULAR
    vec4 specularMapColor = computeSpecularColor(specularSampler, texCoord);
    float spec = CalcSpec(lightDir, normal, viewDir, roughness, metalness);
    vec3 specular = light.color * spec;//material.specular
    vec3 finalSpecular = specularMapColor.xyz * specular;
    color += finalSpecular;
#endif
    
    // attenuation
    color *= attenuation;

    return (color * fShadow);
}
#ifdef TILE_TEST
vec3 CalcTilePointLight(TilePointLight light, vec3 normal, vec3 fragPos, vec3 viewDir, vec3 diffuseColor, float roughness, float metalness, float fShadow)
{
    vec3 lightDir = normalize(vec3(light.position) - fragPos);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);
    // specular shading
    float spec = CalcSpec(lightDir, normal, viewDir, roughness, metalness);
    // attenuation
    float distance = length(vec3(light.position) - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));    
    // combine results
    vec3 ambient = vec3(light.ambient) * diffuseColor * (1.0 - metalness);//material.diffuse
    vec3 diffuse = vec3(light.diffuse) * diff * diffuseColor * (1.0 - metalness);//material.diffuse
    vec3 specular = vec3(light.specular) * spec;//material.specular
    // attenuation
    ambient *= attenuation;
    diffuse *= attenuation;
    specular *= attenuation;
    //return (ambient + diffuse * fShadow + specular * fShadow);
    return diffuse;
    //return vec3(light.diffuse) * diff * diffuseColor * attenuation;
    //return vec3(light.diffuse);
    //return vec3(0.005, 0.0, 0.0);
}
#endif

vec3 CalcBakePointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir, float roughness, float metalness)
{
    vec3 lightDir = normalize(light.position - fragPos);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);

    // attenuation
    float dist = length(light.position - fragPos);
    float attenuation = calculateAttenuation(dist, light.constant, light.linear, light.quadratic); 
    // combine results
    vec3 color = light.color * diff * (1.0 - metalness);//material.diffuse

    // attenuation
    color *= attenuation;

    return (color);
}

// calculates the color when using a spot light.
vec3 CalcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir, vec3 diffuseColor, float roughness, float metalness, float fShadow)
{
    vec3 lightDir = normalize(light.position - fragPos);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);
    // attenuation
    float dist = length(light.position - fragPos);
    float attenuation = calculateAttenuation(dist, light.constant, light.linear, light.quadratic);
    // spotlight intensity
    //float theta = dot(lightDir, normalize(-light.direction));//todo.shader:传光的反方向
    float theta = dot(lightDir, normalize(light.direction)); // 需要 lightDir 从片段指向光源, cosθ
    float epsilon = light.cutOff - light.outerCutOff;
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);
    // combine results
    vec3 color = light.color * light.intensity * diff * diffuseColor * (1.0 - metalness);//material.diffuse


#ifdef EMISSION
    vec3 emissionColor = computeEmissiveColor(vEmissiveSampler, texCoord);
    color += emissionColor;
    color = clamp(color, 0.0, 1.0);
#endif
    // 高光
#ifdef SPECULAR
    vec4 specularMapColor = computeSpecularColor(specularSampler, texCoord);
    float spec = CalcSpec(lightDir, normal, viewDir, roughness, metalness);
    vec3 specular = light.color * spec;//material.specular
    vec3 finalSpecular = specularMapColor.xyz * specular;
    color += finalSpecular;
#endif

    // attenuation
    color *= attenuation * intensity;

    return (color * fShadow);
}

vec3 CalcRectangularAreaLight(RectangularAreaLight light, vec3 normal, vec3 fragPos, vec3 viewDir, vec3 diffuseColor, float roughness, float metalness, float fShadow)
{
    vec3 right = normalize((light.viewMatrix * vec4(vec3(1.0, 0.0, 0.0), 0.0f)).xyz); // 在光的局部空间随意找个 right
    vec3 pnormal = normalize((light.viewMatrix * vec4(light.direction, 0.0f)).xyz);
    vec3 ppos = (light.viewMatrix * vec4(light.position, 0.0f)).xyz;
    vec3 up = normalize(cross(pnormal, right));
    right = normalize(cross(up, pnormal));

    //width and height of the area light:
    float width = light.size.x * 0.5;
    float height = light.size.y * 0.5;

    vec3 V = (light.viewMatrix * vec4(fragPos, 0.0f)).xyz;
    //project onto plane and calculate direction from center to the projection.
    vec3 projection = projectOnPlane(V, ppos, pnormal);// projection in plane
    vec3 dir = projection - ppos;

    //calculate distance from area:
    vec2 diagonal = vec2(dot(dir, right), dot(dir, up));
    vec2 nearest2D = vec2(clamp(diagonal.x, -width, width), clamp(diagonal.y, -height, height));
    vec3 nearestPointInside = ppos + (right * nearest2D.x + up * nearest2D.y);

    float dist = distance(V, nearestPointInside);//real distance to area rectangle

    vec3 L = normalize(nearestPointInside - V);
    float attenuation = calculateAttenuation(dist, light.constant, light.linear, light.quadratic);

    float pnDotL = dot(pnormal, -L);
    float epsilon = light.cutOff - light.outerCutOff;
    float intensity = clamp((pnDotL - light.outerCutOff) / epsilon, 0.0, 1.0);

    if (pnDotL > 0.0f && sideOfPlane(V, ppos, pnormal)) //looking at the plane
    {   
        return light.color * light.intensity * diffuseColor * attenuation * intensity;  
    }

    return vec3(0);
}

#ifdef TILE_TEST
vec3 CalcTileSpotLight(TileSpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir, vec3 diffuseColor, float roughness, float metalness, float fShadow)
{
    vec3 lightDir = normalize(vec3(light.position) - fragPos);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);
    // specular shading
    float spec = CalcSpec(lightDir, normal, viewDir, roughness, metalness);
    // attenuation
    float distance = length(vec3(light.position) - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
    
    // spotlight intensity
    //float theta = dot(lightDir, normalize(-vec3(light.direction)));//todo.shader:传光的反方向
    float theta = dot(lightDir, normalize(vec3(light.direction)));
    float epsilon = light.cutOff - light.outerCutOff;
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);
  
    // combine results
    vec3 ambient = vec3(light.ambient) * diffuseColor * (1.0 - metalness);//material.diffuse
    vec3 diffuse = vec3(light.diffuse) * diff * diffuseColor * (1.0 - metalness);//material.diffuse
    vec3 specular = vec3(light.specular) * spec;//material.specular
    // attenuation
    ambient *= attenuation;// * intensity;
    diffuse *= attenuation;// * intensity;
    specular *= attenuation;// * intensity;
    return (ambient + diffuse * fShadow + specular * fShadow);
    //return vec3(0.5, 0.0, 0.0);
    //return vec3(light.diffuse);
    //return vec3(diffuseColor); // normal对 metalness对 roughness对 diffuseColor对
}
#endif

// calculates the color when using a spot light.
vec3 CalcBakeSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir, float metalness)
{
    vec3 lightDir = normalize(light.position - fragPos);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);

    // attenuation
    float distance = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
    // spotlight intensity
    //float theta = dot(lightDir, normalize(-light.direction));//todo.shader:传光的反方向
    float theta = dot(lightDir, normalize(light.direction));
    float epsilon = light.cutOff - light.outerCutOff;
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);
    // combine results
    vec3 color = light.color * light.intensity * diff * (1.0 - metalness);//material.diffuse

    // attenuation
    color *= attenuation * intensity;
    return (color);
}

vec4 getLightMap();

vec3 CalcPixelLight(vec3 worldNormal, vec3 worldPos, vec4 diffuseColor, float ignoreMainLight, float useBakePointLight, float bakeShadowIntensity)
{
    // properties
    vec3 norm = normalize(worldNormal);//todo.shader:去掉这两处normalize
    vec3 viewDir = normalize(viewPos - worldPos);

    float diff = max(dot(norm, normalize(dirLight.direction)), 0.0);
    float fShadow = getShadow(diff);
    vec4 lightmap = getLightMap(); // 应为合批和非合批的 getLightMap 实现不同，改为 fs(ps) 提供具体实现。
    float bakeShadow = lightmap.a * bakeShadowIntensity;
    fShadow = clamp((1.0 - (bakeShadow + fShadow)) , 0.0, 1.0);

    // == =====================================================
    // Our lighting is set up in 3 phases: directional, point lights and an optional flashlight
    // For each phase, a calculate function is defined that calculates the corresponding color
    // per lamp. In the main() function we take all the calculated colors and sum them up for
    // this fragment's final color.
    // == =====================================================
    // phase 1: directional lighting
    vec3 hdrColor = CalcAmbientLight(ambientLight, norm, viewDir, diffuseColor.rgb, material.metalness);

    hdrColor += CalcDirLight(dirLight, norm, viewDir, diffuseColor.rgb, material.roughness, material.metalness, fShadow);

    hdrColor = hdrColor * (1.0 - ignoreMainLight) + vec3(diffuseColor.rgb) * (ignoreMainLight);

#if defined(TILE_TEST)

    // phase 2: point lights
    for(int i = 0; i < /*MAX_TILE_POINT_LIGHT*/10; i++)
        hdrColor += CalcTilePointLight(tilePointLights[i], norm, worldPos, viewDir, diffuseColor.rgb, material.roughness, material.metalness, fShadow);
    // phase 3: spot light
    for(int i = 4; i < /*MAX_TILE_SPOT_LIGHT*/5; i++)
        hdrColor += CalcTileSpotLight(tileSpotLights[i], norm, worldPos, viewDir, diffuseColor.rgb, material.roughness, material.metalness, fShadow);

#elif defined(BAKE_LIGHT)

	hdrColor += (lightmap.rgb * diffuseColor.rgb * useBakePointLight);

#else

    // phase 2: point lights
    for(int i = 0; i < NR_POINT_LIGHTS; i++)
        hdrColor += CalcPointLight(pointLights[i], norm, worldPos, viewDir, diffuseColor.rgb, material.roughness, material.metalness, fShadow);
    // phase 3: spot light
    for(int i = 0; i < NR_SPOT_LIGHTS; i++)
       hdrColor += CalcSpotLight(spotLights[i], norm, worldPos, viewDir, diffuseColor.rgb, material.roughness, material.metalness, fShadow);

    for(int i = 0; i < NR_AREA_LIGHTS; i++)
       hdrColor += CalcRectangularAreaLight(areaLights[i], norm, worldPos, viewDir, diffuseColor.rgb, material.roughness, material.metalness, fShadow);
#endif

    vec3 result = toneMapping(hdrColor);

    return result;
    //return vec3(fShadow);
}

vec3 CalcPixelLight(vec3 worldNormal, vec3 worldPos, vec4 diffuseColor)
{
    return CalcPixelLight(worldNormal, worldPos, diffuseColor, 0.0, 0.0, 0.0);
}
