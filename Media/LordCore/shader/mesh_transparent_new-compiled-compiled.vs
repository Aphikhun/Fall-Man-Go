#version 300 es
precision mediump float;

// #define LOWEFFECT
// #define ALPHATEST
// #define USEFOG

#ifdef USEFOG
﻿#version 300 es
#define GLSLIFY 1
#define GLSLIFY 1
#define GLSLIFY 1

[VS]
#pragma once

#ifndef NEW_FOG
#ifdef USEFOG
uniform vec4 fogParam[3];
out vec4 fogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}

vec4 CalcFogColor(vec4 fogParam[3], vec4 vWorldPos)
{
	return vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
}
#define FOG_VS(worldPos) fogColor = CalcFogColor(fogParam, worldPos);
#else
#define FOG_VS(worldPos)
#endif  // USEFOG
#else
#define FOG_VS(worldPos)
#endif  // NEW_FOG

[PS]
#pragma once

#ifdef NEW_FOG

uniform mediump vec4 fogParam[3];

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

mediump vec4 CalcFogColor()
{
	return vec4(fogParam[1].rgb, ComputeFog(gl_FragCoord.z, gl_FragCoord.w, fogParam[0].z, fogParam[0].x, fogParam[0].y, fogParam[0].w, fogParam[2]));
}

#else

#ifdef USEFOG

in vec4 fogColor;

mediump vec4 CalcFogColor()
{
	return fogColor;
}
#else

mediump vec4 CalcFogColor()
{
	return vec4(0.2, 0.2, 0.2, 0.5);
}

#endif // USEFOG

#endif // NEW_FOG

#endif

in vec3 inPosition;
in vec3 inNormal;
in vec2 inTexCoord;

uniform mat4 matWorld;
uniform mat4 matWVP;
#ifndef LOWEFFECT
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec3 subLightDir;
uniform vec4 subLightColor;
uniform vec4 ambient;
uniform mat4 lightSpaceMatrix;
#endif
uniform mediump vec4 multiCalColor;

out vec4 color;
out vec2 texCoord;
#ifndef LOWEFFECT
out vec3 normal;
out vec4 FragPosLightSpace;
out vec3 vMainLightDir;
out vec4 vMainLightColor;
#else
out float vDiscardAlpha;
#endif

out float useOverlayColorReplaceMode;

invariant gl_Position;

void main(void)
{
	vec4 vWorldPos = matWorld * vec4(inPosition, 1.0);
	gl_Position = matWVP * vec4(inPosition, 1.0);
		
	texCoord = inTexCoord;
	
#ifndef LOWEFFECT
	vec3 vNorm = normalize(mat3(matWorld) * inNormal);
	
	float mainParam = max(dot(mainLightDir, vNorm), 0.0);
	float subParam = max(dot(subLightDir, vNorm), 0.0);

	normal = vNorm;
	
	color = mainParam * mainLightColor + subParam * subLightColor + ambient;
	color.a = 1.0;
	color.rgb = color.rgb * multiCalColor.rgb;
#else
    color = multiCalColor;
    color.a = alphaColor.a + inNormal.x * 0.00001;
    // color.a += inNormal.x * 0.00001;
    vDiscardAlpha = discardAlpha;
#endif

#ifdef USEFOG
#ifndef NEW_FOG
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif
#endif

#ifndef LOWEFFECT
	FragPosLightSpace = lightSpaceMatrix * vWorldPos;
	vMainLightDir = mainLightDir;
	vMainLightColor = mainLightColor;
#endif
	
	useOverlayColorReplaceMode = multiCalColor.a;
}
