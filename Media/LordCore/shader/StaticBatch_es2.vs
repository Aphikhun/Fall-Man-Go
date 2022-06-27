#version 100    
attribute vec3 inPosition;          // xyz:  世界空间位置
attribute vec2 inTexCoord;          // xy:   纹理坐标
attribute vec4 inNormal;            // xyz:  法线(0~255)        w: 材质
attribute vec4 inColor;             // rgba: 0~255

uniform mat4 matVP;
uniform mat4 matLightSapce;
uniform mediump vec2 uMaterialLayer[24];    // xy 图集上对应材质的初始纹理位置

varying vec3 ourPosition;           
varying vec4 ourTexcoord;                   // xy纹理坐标:  zw:图集上的图层
varying vec3 ourNormal;             
varying vec4 ourColor;     
varying vec4 ourLightSpacePos;              // 不适用. 和 es3 保持一致  

mediump vec4 getUV(int matIndex)
{
    vec2 offset = uMaterialLayer[matIndex];
    return vec4(inTexCoord, offset);
}

void main() 
{
    ourPosition = inPosition;
    ourTexcoord = getUV(int(inNormal.w));
    ourNormal   = inNormal.xyz * (1.0 / 127.0) - 1.0;
    ourColor    = inColor.rgba * (1.0 / 255.0);

    vec4 worldPosition = vec4(inPosition, 1.0);
    ourLightSpacePos   = matLightSapce * worldPosition;
    gl_Position        = matVP * worldPosition;
}