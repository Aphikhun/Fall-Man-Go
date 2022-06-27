#version 300 es

precision mediump float;

#include "headers/math/matrix.glsl"												// 教程版会用到
// #include "headers/shadow.glsl"
// #include "headers/lighting.glsl"


////////////////////////////////////////////////////
//part的参数
layout(location = 0) in highp vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTexCoord;
layout(location = 3) in vec2 inTexCoord1;

uniform mat4 matWorld;
uniform mat4 matWVP;
uniform vec2 bakeScale;
uniform vec2 bakeOffset;
uniform mat4 lightSpaceMatrix[4];

out vec3 worldPos;
out vec3 worldNormal;
out vec4 FragPosLightSpace;

invariant gl_Position;
////////////////////////////////////////////////////


void main(void)
{
	worldPos = vec3(matWorld * vec4(inPosition, 1.0));

	worldNormal = normalize(mat3(matWorld) * inNormal);							// BM老实现
	//worldNormal = mat3(transpose_mat4(inverse_mat4(matWorld))) * inNormal;	// 教程版，非优化
	//worldNormal = matNormal * inNormal;										// 新实现，正规矩阵 //todo.shader:最终使用这个
	
	//texCoord = inTexCoord;

	FragPosLightSpace = lightSpaceMatrix[0] * vec4(worldPos, 1.0);

    gl_Position = vec4(vec2(inTexCoord1.xy * bakeScale + bakeOffset) * 2.0 - 1.0, 0.0, 1.0);
}
