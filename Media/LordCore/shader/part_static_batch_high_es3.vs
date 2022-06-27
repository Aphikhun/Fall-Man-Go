#version 300 es

precision mediump float;

#include "headers/math/matrix.glsl"												
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#include "headers/fog.glsl"

layout(location = 0) in highp vec3 inPosition;    // xyz:  世界空间位置
layout(location = 1) in vec2 inTexCoord;          // xy:   纹理坐标
layout(location = 2) in vec4 inNormal;            // xyz:  法线(0~255)        w: 材质
layout(location = 3) in vec4 inColor;             // rgba: 0~255

uniform highp mat4 matViewProj;

#ifdef BLOCKMAN_EDITOR
    uniform mediump mat4 matModel;
#endif

mediump vec3 getUV(float matIndex)
{
    return vec3(inTexCoord, matIndex + 0.5);        // 在 ps中会对matIndex转换成整型, 为了避免插值引起小于matIndex, 所以加上0.5
}

out vec3  ourPosition;
out vec3  ourNormal;
out vec3  ourTexcoord;
out vec4  ourColor;

void main() {
    highp vec4 worldPosition = vec4(inPosition, 1.0);

    //just use in editor - by chentiansheng
#ifdef BLOCKMAN_EDITOR
    worldPosition = matModel * worldPosition;
#endif
    gl_Position      = matViewProj * worldPosition;

    ourPosition      = vec3(worldPosition);
    ourNormal        = inNormal.xyz * (2.0 / 255.0) - 1.0;
    ourTexcoord      = getUV(inNormal.w);
    ourColor         = inColor * (1.0 / 255.0);

    /// shadow map
    mat4 matWorld = mat4(1.0);
	SHADOW_VS(vec4(inPosition, 1.0));
}
