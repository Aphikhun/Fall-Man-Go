#version 300 es

precision mediump float;

#include "headers/defer_basic.glsl"
#include "headers/math/matrix.glsl"												// 教程版会用到

//part的参数

layout(location = 3) in vec3 inTexCoord1;
layout(location = 4) in vec3 inTexCoord2;

uniform vec3 scale;
uniform float tillScale;
uniform float isCube;

out vec2 lightMapUV;

void main(void)
{
	worldPos = vec4(matWorld * inPosition);

	worldNormal = normalize(mat3(matWorld) * inNormal);									// BM老实现，todo.shader:defer的normalize可以去掉
	//worldNormal = mat3(transpose_mat4(inverse_mat4(matWorld))) * inNormal;	// 教程版，非优化
	//worldNormal = matNormal * inNormal;										// 新实现，正规矩阵 //todo.shader:最终使用这个
	
	vec3 N = abs(inNormal);
	vec3 tex3 = (inPosition + 0.5) * scale;
	vec2 texcoordCube = (N.x > 0.99 ? tex3.zy : (N.y > 0.99 ? tex3.zx : tex3.xy));
	texcoordCube.x = 1.0- texcoordCube.x;
	vec2 texcoordUnion = (inTexCoord * scale).xy;
	vec2 texcoord1 = N.y > 0.99 ? tex3.zx : (inTexCoord * scale).xy;
	//texCoord = (isCube == 1.0) ? texcoordCube : (isCube == 0.0 ? texcoordUnion : texcoord1);
	texCoord = (isCube == 0.0) ? texcoordUnion : texcoord1;

	lightMapUV = inTexCoord1.xy;

	gl_Position = matWVP * inPosition;
}
