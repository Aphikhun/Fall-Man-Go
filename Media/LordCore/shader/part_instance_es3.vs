#version 300 es
#include "headers/math/matrix.glsl"												
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#include "headers/fog.glsl"

// mesh data
layout(location = 0) in highp vec3  inPosition;
layout(location = 1) in vec3  inNormal;
layout(location = 2) in vec2  inTexCoord;
// instance data
layout(location = 3) in mat4  inMatWorld;
layout(location = 7) in vec3  inTexcoordScale;
layout(location = 8) in float inMaterialIndex;
layout(location = 9) in vec4  inColor;

uniform mat4 matViewProj;
uniform float isCube;

vec2 CalcTexcoord() {
    vec3 N = abs(inNormal);
    vec3 tex3 = (inPosition + 0.5) * inTexcoordScale;
	vec2 texcoordCube = (N.x > 0.99 ? tex3.zy : (N.y > 0.99 ? tex3.zx : tex3.xy));
	texcoordCube.x = 1.0- texcoordCube.x;
	vec2 texcoordUnion = inTexCoord * inTexcoordScale.xy;
	vec2 texcoord1 = N.y > 0.99 ? tex3.zx : inTexCoord * inTexcoordScale.xy;
	return (isCube == 1.0) ? texcoordCube : (isCube == 0.0 ? texcoordUnion : texcoord1);
}

out highp vec3  ourPosition;
out highp vec2  ourTexcoord;
out vec3  ourNormal;
out vec4  ourColor;
out float outMaterialIndex; 
void main() {
    vec4 worldPosition = inMatWorld * vec4(inPosition, 1.0);
    gl_Position      = matViewProj * worldPosition;
    ourPosition      = vec3(worldPosition);
    ourNormal        = vec3(transpose(inverse(inMatWorld)) * vec4(inNormal, 0.0));
    ourTexcoord      = CalcTexcoord();
    ourColor         = inColor * (1.0 / 255.0);
    outMaterialIndex = inMaterialIndex + 0.5;

    /// shadow map
    mat4 matWorld = inMatWorld;
	SHADOW_VS(vec4(inPosition, 1.0));
}