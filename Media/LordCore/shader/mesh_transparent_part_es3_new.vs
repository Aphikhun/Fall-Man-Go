#version 300 es
precision mediump float;

// #define UV2
// #define LOWEFFECT
// #define USEFOG

#include "headers/math/matrix.glsl"												// 教程版会用到
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"

#ifdef USEFOG
#include "headers/fog.glsl"
#endif

////////////////////////////////////////////////////
//part的参数
in highp vec3 inPosition;
in vec3 inNormal;
in vec3 inTexCoord;
in vec3 inTexCoord1;
#ifdef UV2
in vec3 inTexCoord2;
uniform float tillScale;
#endif

#ifdef USEBATCH
#ifndef UV2
in vec3 inTexCoord2;
#endif
in vec3 inTexCoord3;
#endif

uniform highp mat4 matWorld;
uniform highp mat4 matWVP;
//uniform mat4 matNormal

out highp vec3 worldPos;
out vec3 worldNormal;
out vec2 texCoord;
#ifndef LOWEFFECT
	out vec2 lightMapUV;
	#ifndef NEWLIGHT
		out vec3 lightFactor;
	#endif
#else
	out vec3 lightFactor;
#ifdef STATICPART
	out vec2 lightMapUV;
#endif
#endif

#ifdef USEBATCH
out vec3 texCoordLightMap;
out vec3 texCoordBatch1;
out vec3 texCoordBatch2;
#endif

// #ifndef LOWEFFECT
uniform vec4 ambientColor;
uniform float ambientStrength;
// #endif

uniform vec3 scale;
invariant gl_Position;
////////////////////////////////////////////////////

#ifdef INSTANCE
uniform mediump float useGPUInstance;
out vec4 gpuinstanceColor;
#endif


void main(void)
{
	worldPos = vec3(matWorld * vec4(inPosition, 1.0));

	worldNormal = normalize(mat3(matWorld) * inNormal);
	
// #ifndef UV2
//     texCoord = vec2(inTexCoord);
// #else
//     texCoord = vec2(dot(scale, inTexCoord), dot(scale, inTexCoord2));
// #endif
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
#ifndef USEBATCH
	texCoord = vec2(inTexCoord);
#else
#ifndef UV2
	texCoord = vec2(inTexCoord);
#else
	vec3 N = abs(inNormal);
	vec3 tex3 = (inPosition + 0.5) * scale;
	vec2 texcoordCube = (N.x > 0.99 ? tex3.zy : (N.y > 0.99 ? tex3.zx : tex3.xy));
	texcoordCube.x = 1.0- texcoordCube.x;
	vec2 texcoordUnion = (inTexCoord * scale * tillScale).xy;
	vec2 texcoord1 = N.y > 0.99 ? tex3.zx : (inTexCoord * scale * tillScale).xy;
	//texCoord = (isCube == 1.0) ? texcoordCube : (isCube == 0.0 ? texcoordUnion : texcoord1);
	texCoord = (isCube == 0.0) ? texcoordUnion : texcoord1;
#endif
	texCoordLightMap = inTexCoord1;
	texCoordBatch1 = inTexCoord2;
	texCoordBatch2 = inTexCoord3;
#endif
	
	SHADOW_VS(vec4(inPosition, 1.0));

	vec4 worldPosV4 = matWorld * vec4(inPosition, 1.0);

#ifndef USEFOG
#else
	FOG_VS(worldPosV4);
#endif

#ifndef LOWEFFECT
	#ifdef NEWLIGHT
		lightMapUV = inTexCoord1.xy;
	#else
		// Ambient
		mediump vec3 ambient = ambientStrength * 0.6 * ambientColor.rgb;
		
		// Diffuse 
		mediump vec3 norm = normalize(mat3(matWorld) * inNormal);
		mediump vec3 lightDir = normalize(mainLightDir);
		mediump float diff = max(dot(norm, lightDir), 0.0);
		mediump vec3 diffuse = diff * mainLightColor.rgb;

		// Specular
		mediump vec3 specular = vec3(0.0);
		mediump float specularStrength = 0.5;
		mediump vec3 viewDir = normalize(viewPos - worldPos.xyz);
		mediump vec3 reflectDir = reflect(-lightDir, norm);
		float specSrc = max(dot(viewDir, reflectDir), 0.0);
		mediump float spec = specSrc * specSrc * specSrc * specSrc;
		spec = spec * spec;
		spec = spec * spec;
		spec = spec * spec;
		specular = specularStrength * spec * mainLightColor.rgb;
		lightFactor = ambient + diffuse + specular;
	#endif
#else
	// Ambient
    mediump vec3 ambient = ambientStrength * 0.6 * ambientColor.rgb;
  	
    // Diffuse 
    mediump vec3 norm = normalize(mat3(matWorld) * inNormal);
    mediump vec3 lightDir = normalize(mainLightDir);
    mediump float diff = max(dot(norm, lightDir), 0.0);
    mediump vec3 diffuse = diff * mainLightColor.rgb;

    // Specular
    mediump vec3 specular = vec3(0.0);
    mediump float specularStrength = 0.5;
    mediump vec3 viewDir = normalize(viewPos - worldPos.xyz);
    mediump vec3 reflectDir = reflect(-lightDir, norm);
	float specSrc = max(dot(viewDir, reflectDir), 0.0);
    mediump float spec = specSrc * specSrc * specSrc * specSrc;
	spec = spec * spec;
	spec = spec * spec;
	spec = spec * spec;
    specular = specularStrength * spec * mainLightColor.rgb;
	lightFactor = ambient + diffuse + specular;

#ifdef STATICPART
	lightMapUV  = inTexCoord1.xy;
#endif
#endif

#ifndef INSTANCE
	gl_Position = matWVP * vec4(inPosition, 1.0);
#else
	mat4 vRealMatWorld = (useGPUInstance > 0.9 ? inGpuInstanceMat : matWorld);
	gl_Position = matVP * vRealMatWorld * vec4(inPosition, 1.0);
#endif
	// mesh_transparent_part_es3_new.vs
}
