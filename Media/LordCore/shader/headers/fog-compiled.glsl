#version 300 es
#define GLSLIFY 1

[VS]
#pragma once

// #ifndef NEW_FOG
// #ifdef USEFOG
// uniform vec4 fogParam[3];
// out vec4 fogColor;

// float ComputeFog(vec3 camToWorldPos, vec3 param)
// {
// 	float fdist = max(length(camToWorldPos) - param.x, 0.0);
// 	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
// 	return 1.0 - density;
// }

// vec4 CalcFogColor(vec4 fogParam[3], vec4 vWorldPos)
// {
// 	return vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
// }
// #define FOG_VS(worldPos) fogColor = CalcFogColor(fogParam, worldPos);
// #else
// #define FOG_VS(worldPos)
// #endif  // USEFOG
// #else
// #define FOG_VS(worldPos)

#ifndef NEW_FOG

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

#endif

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
