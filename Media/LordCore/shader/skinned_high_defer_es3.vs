#version 300 es

precision mediump float;

#include "headers/defer_basic.glsl"
#include "headers/math/matrix.glsl"													// 教程版会用到
#include "headers/shadow.glsl"
#include "headers/fog.glsl"
#include "headers/skinned.glsl"

void main(void)
{
	vec3 skinnedPos = GetSkinnedPos();
	vec3 skinnedNormal = GetSkinnedNormal();

	worldPos = matWorld * vec4(skinnedPos, 1.0);

	worldNormal = mat3(matWorld) * skinnedNormal;									// BM老实现，todo.shader:defer的normalize可以去掉
	//worldNormal = mat3(transpose_mat4(inverse_mat4(matWorld))) * skinnedNormal;	// 教程版，非优化
	//worldNormal = matNormal * skinnedNormal;										// 新实现，正规矩阵 //todo.shader:最终使用这个
	
	texCoord = vec2(inTexCoord);

	gl_Position = matWVP * vec4(skinnedPos, 1.0);

}
