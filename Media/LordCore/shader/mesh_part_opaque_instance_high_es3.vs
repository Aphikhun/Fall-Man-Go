#version 300 es
#include "headers/math/matrix.glsl"												
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#define NEW_FOG
#include "headers/fog.glsl"

// mesh data
layout(location = 0) in highp vec3  inPosition;
layout(location = 1) in vec3  inNormal;
layout(location = 2) in vec3  inTexCoord;
// instance data
layout(location = 3)  in mat4  inMatWorld;
layout(location = 7)  in vec4  inNaturalColor;
layout(location = 8)  in vec4  inCustomColor;
layout(location = 9)  in vec4  inSubMeshColor;
layout(location = 10) in vec4  inMultiCalColor;
layout(location = 11) in vec4  inParame0;               // .xyz:inUvParam           .w:inDiscardAlpha 
layout(location = 12) in vec4  inParame1;               // .xyz:inSubMeshUVParam    .w:inAlpha
layout(location = 13) in vec4  inParame2;               // .x:inIsSubMesh .y:inCustomThreshold .z:inUseTextureAlpha .w: inSubMeshAlpha
layout(location = 14) in vec4  inParame3;               // .xyz: subMeshOffsetParam
 
uniform mat4 matViewProj;
uniform mat4 matLightSpace;

out vec4 ourLightSpacePos;
out vec3 ourPosition;
out vec3 ourNormal;
out vec2 ourTexcoord;
out vec4 ourNaturalColor;
out vec4 ourCustomColor;
out vec4 ourSubMeshColor;
out vec4 ourMultiCalColor;
out vec4 ourParame0;               // .xyz:inUvParam           .w:inDiscardAlpha 
out vec4 ourParame1;               // .xyz:inSubMeshUVParam    .w:inAlpha
out vec4 ourParame2;               // .x:inIsSubMesh .y:inCustomThreshold .z:inUseTextureAlpha
out vec4 ourParame3;               // .xyz: subMeshOffsetParam


void main() {
    vec4 worldPosition = inMatWorld * vec4(inPosition, 1.0);
    gl_Position = matViewProj * worldPosition;
    ourLightSpacePos = matLightSpace * worldPosition;
    ourPosition = vec3(worldPosition);
    ourNormal = (transpose(inverse(inMatWorld)) * vec4(inNormal, 0.0)).xyz;
    ourTexcoord = inTexCoord.xy;
    ourNaturalColor = inNaturalColor;
    ourCustomColor = inCustomColor;
    ourSubMeshColor = inSubMeshColor;
    ourMultiCalColor = inMultiCalColor;
    ourParame0 = inParame0;
    ourParame1 = inParame1;
    ourParame2 = inParame2;
    ourParame3 = inParame3;

    /// shadow map
    mat4 matWorld = inMatWorld;
	SHADOW_VS(vec4(inPosition, 1.0));
}