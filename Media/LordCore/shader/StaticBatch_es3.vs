#version 300 es
layout(location = 0) in vec3 inPosition;          // xyz:  世界空间位置
layout(location = 1) in vec2 inTexCoord;          // xy:   纹理坐标
layout(location = 2) in vec4 inNormal;            // xyz:  法线(0~255)        w: 材质
layout(location = 3) in vec4 inColor;             // rgba: 0~255

uniform mat4 matVP;
uniform mat4 matLightSapce;

out vec3 ourPosition;           
out vec3 ourTexcoord;                               // xy纹理坐标:  zw:图集上的图层
out vec3 ourNormal;             
out vec4 ourColor;     
out vec4 ourLightSpacePos;             

mediump vec3 getUV(float matIndex)
{
    return vec3(inTexCoord, matIndex + 0.5);        // 在 ps中会对matIndex转换成整型, 为了避免插值引起小于matIndex, 所以加上0.5
}

void main() 
{
    ourPosition = inPosition;
    ourTexcoord = getUV(inNormal.w);
    ourNormal   = inNormal.xyz * (1.0 / 127.0) - 1.0;
    ourColor    = inColor.rgba * (1.0 / 255.0);

    vec4 worldPosition = vec4(inPosition, 1.0);
    ourLightSpacePos   = matLightSapce * worldPosition;
    gl_Position        = matVP * worldPosition;
}