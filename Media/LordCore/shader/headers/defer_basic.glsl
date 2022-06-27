#version 300 es

[VS]
#pragma once

layout(location = 0) in highp vec4 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec3 inTexCoord;

uniform mat4 matWorld;
uniform mat4 matWVP;
uniform mat4 matNormal;//正规矩阵，防止平移或非等比缩放 对 normal的破坏。https://learnopengl-cn.readthedocs.io/zh/latest/02%20Lighting/02%20Basic%20Lighting/

out vec4 worldPos;
out vec3 worldNormal;
out vec2 texCoord;

invariant gl_Position;

[PS]
#pragma once

#include "headers/material.glsl"

in vec4 worldPos;
in vec3 worldNormal;
in vec2 texCoord;

layout (location = 0) out vec4 gNormalRough;
layout (location = 1) out vec4 gAlbedoSpec;

void DrawToGBuffers(vec4 diffuse)
{
    gNormalRough.rgb = normalize(worldNormal);					            // todo.shader 即使模型的vs已经normalize了 但是这里不能去掉
    gNormalRough.a = material.roughness;
    // and the diffuse per-fragment color
    gAlbedoSpec.rgb = diffuse.rgb;
    gAlbedoSpec.a = material.metalness;                                     // specular改成后面算 // store specular intensity in gAlbedoSpec's alpha component

    
    // engine-core\dev\engine\Src\Core\Render\RenderStage\DeferredSceneColorRenderStage.h
    // https://zhuanlan.zhihu.com/p/21961722
    // rgb = normal【       法线       】	a = roughness【 粗糙度 】
    // rgb = albedo【 纹理颜色或预计算 】	a = specular 【 金属度 】
}
