#version 300 es
layout(location = 0) in highp vec4 inPosition;         // xyz:位置,      w:三角形索引
layout(location = 1) in vec4 inNormal;           // xyz:法线       w随机数种子0
layout(location = 2) in vec4 inBlendWeights;     // xyz:三顶点材质, w随机数种子1
layout(location = 3) in vec4 inBlendIndices;     // xyz:三顶点投影, w随机数种子2

uniform vec4 uPositionTranslate;    // xyz:偏移量, w缩放
uniform mat4 matVP;
uniform mat4 matLightSpaceMatrix;

uniform mediump vec3 uProjectionTangents[26];          // 计算纹理 u 坐标
uniform mediump vec3 uProjectionBitangent[26];         // 计算纹理 v 坐标
uniform mediump vec4 uMaterialLayer[24];               // x纹理坐标的缩放; y随机化纹理控制值; zw 图集上对应材质的初始纹理位置

float random(vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.2323)) * 43758.5453123));
}

mediump vec3 getUV(vec3 wpos, int projection, float matIndex, float seed) 
{
    mediump int index = int(projection);
    vec3 u = uProjectionTangents[index];
    vec3 v = uProjectionBitangent[index];
    vec4 material = uMaterialLayer[int(matIndex)];
    seed = seed * (1.0 / 255.0);
    vec2 uvOffset = material.y * vec2(seed, seed * 0.61235); 
    vec2 texcoord = vec2(dot(wpos, u), dot(wpos, v)) * material.x + uvOffset;
    return vec3(texcoord, matIndex - 0.5);  // matIndex - 0.5. 本来是需要 -1 的. 但是为了避免插值精度误差, 所以 -0.5, 展示需要一个整型的索引而已
}

out vec3 wpos;
out vec3 wnrm;
out vec3 barycentric;
out vec4 fragPosLightSpace;
out vec3 texcoord0;
out vec3 texcoord1;
out vec3 texcoord2;

void main() 
{
    vec3 worldPos = (inPosition.xyz * uPositionTranslate.w) + uPositionTranslate.xyz;
    vec4 wpos4 = vec4(worldPos, 1.0);
    fragPosLightSpace = matLightSpaceMatrix * wpos4;

    wnrm = inNormal.xyz * (1.0 / 127.0) - 1.0;
    wpos = wpos4.xyz;
    barycentric = vec3(0.0, 0.0, 0.0);
    barycentric[int(inPosition.w)] = 1.0;

    texcoord0 = getUV(wpos, int(inBlendIndices.x), inBlendWeights.x, inNormal.w);
    texcoord1 = getUV(wpos, int(inBlendIndices.y), inBlendWeights.y, inBlendWeights.w);
    texcoord2 = getUV(wpos, int(inBlendIndices.z), inBlendWeights.z, inBlendIndices.w);
    gl_Position = matVP * wpos4;
}