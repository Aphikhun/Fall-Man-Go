#version 300 es

precision mediump float;

#include "headers/defer_basic.glsl"
#include "headers/math/matrix.glsl"												// 教程版会用到

//part的参数

layout(location = 3) in vec3 inTexCoord1;
layout(location = 4) in vec3 inTexCoord2;

out float useOverlayColorReplaceMode;
out vec2 lightMapUV;

void main(void)
{
	worldPos = vec4(matWorld * inPosition);

	worldNormal = normalize(mat3(matWorld) * inNormal);									// BM老实现，todo.shader:defer的normalize可以去掉
	//worldNormal = mat3(transpose_mat4(inverse_mat4(matWorld))) * inNormal;	// 教程版，非优化
	//worldNormal = matNormal * inNormal;										// 新实现，正规矩阵 //todo.shader:最终使用这个
	
    texCoord = vec2(inTexCoord);

	//lightMapUV = inTexCoord1.xy;

	gl_Position = matWVP * vec4(inPosition.xyz, 1.0);
}
