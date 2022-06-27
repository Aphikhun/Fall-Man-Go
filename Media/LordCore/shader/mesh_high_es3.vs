#version 300 es

precision mediump float;

#include "headers/basic.glsl"
#include "headers/math/matrix.glsl"												// 教程版会用到
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#include "headers/fog.glsl"

void main(void)
{
	worldPos = vec3(matWorld * inPosition);

	worldNormal = normalize(mat3(matWorld) * inNormal);							// BM老实现
	//worldNormal = mat3(transpose_mat4(inverse_mat4(matWorld))) * inNormal;	// 教程版，非优化
	//worldNormal = matNormal * inNormal;										// 新实现，正规矩阵 //todo.shader:最终使用这个
	
	texCoord = inTexCoord;

	gl_Position = matWVP * inPosition;

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	vec4 vWorldPos = matWorld * inPosition;
	
	SHADOW_VS(inPosition);

	FOG_VS(vWorldPos);
	
}
