#version 300 es

precision mediump float;

#include "headers/basic.glsl"
#include "headers/math/matrix.glsl"													// 教程版会用到
#include "headers/skinned.glsl"
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#include "headers/fog.glsl"



void main(void)
{
	vec3 skinnedPos = GetSkinnedPos();
	vec3 skinnedNormal = GetSkinnedNormal();

	worldPos = vec3(matWorld * vec4(skinnedPos, 1.0));

	worldNormal = normalize(mat3(matWorld) * skinnedNormal);						// BM老实现
	//worldNormal = mat3(transpose_mat4(inverse_mat4(matWorld))) * skinnedNormal;	// 教程版，非优化
	//worldNormal = matNormal * skinnedNormal;										// 新实现，正规矩阵 //todo.shader:最终使用这个
	
	texCoord = inTexCoord;

	gl_Position = matWVP * vec4(skinnedPos, 1.0);

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	vec4 vWorldPos = matWorld * vec4(skinnedPos, 1.0);
	
	SHADOW_VS(vec4(skinnedPos, 1.0));

	FOG_VS(vWorldPos);
	
}
