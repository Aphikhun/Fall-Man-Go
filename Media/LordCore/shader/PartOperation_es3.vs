#version 300 es
layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec2 inTexCoord;
layout(location = 2) in vec4 inNormal;
layout(location = 3) in vec4 inColor;

uniform mat4 matViewProj;
uniform mat4 matWorld;
uniform mat4 matLightSapce;

out mediump vec3 ourPosition;
out mediump vec2 ourTexcoord;
out mediump vec3 ourNormal;
out mediump vec4 ourColor;    
out mediump vec4 ourLightSpacePosition;


void main() {
    vec4 worldPosition = matWorld * vec4(inPosition, 1.0);
    vec3 normal = inNormal.xyz * (1.0 / 127.0) - 1.0;             // [0, 255] -> [-1, +1]
    vec4 worldNormal = matWorld * vec4(normal, 0.0);       // matWorld 一定是等比缩放
    ourPosition = worldPosition.xyz;
    ourTexcoord = inTexCoord;
    ourNormal = worldNormal.xyz;
    ourColor = inColor;
    ourLightSpacePosition = matLightSapce * worldPosition;
    gl_Position = matViewProj * worldPosition;
}