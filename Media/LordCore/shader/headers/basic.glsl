#version 300 es

[VS]
#pragma once

in highp vec4 inPosition;
in vec3 inNormal;
in vec2 inTexCoord;

uniform mat4 matWorld;
uniform mat4 matWVP;
uniform mat4 matNormal;//正规矩阵，防止平移或非等比缩放 对 normal的破坏。https://learnopengl-cn.readthedocs.io/zh/latest/02%20Lighting/02%20Basic%20Lighting/

out highp vec3 worldPos;
out vec3 worldNormal;
out vec2 texCoord;

invariant gl_Position;

[PS]
#pragma once

uniform sampler2D texSampler;
in highp vec3 worldPos;
in vec3 worldNormal;
in vec2 texCoord;

