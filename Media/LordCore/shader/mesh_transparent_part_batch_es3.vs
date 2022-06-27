#version 300 es

precision mediump float;

#include "headers/math/matrix.glsl"												// 教程版会用到
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"
#include "headers/fog.glsl"


////////////////////////////////////////////////////
//part的参数
layout(location = 0) in highp vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTexCoord;//vec3->vec2
layout(location = 3) in vec3 inTexCoord1;
layout(location = 4) in vec2 inTexCoord2;//batch需要的大图uv
layout(location = 5) in vec2 inTexCoord3;//batch需要的大图uv

uniform highp mat4 matWorld;
uniform highp mat4 matWVP;
uniform highp mat4 matVP;
//uniform mat4 matNormal;//正规矩阵，防止平移或非等比缩放 对 normal的破坏。https://learnopengl-cn.readthedocs.io/zh/latest/02%20Lighting/02%20Basic%20Lighting/

out highp vec3 worldPos;
out vec3 worldNormal;
out vec2 texCoord;
out vec3 texCoordLightMap;
out vec2 texCoordBatch1;
out vec2 texCoordBatch2;

uniform vec3 scale;
uniform float tillScale;

invariant gl_Position;
////////////////////////////////////////////////////


void main(void)
{
	worldPos = vec3(/* matWorld * */vec4(inPosition, 1.0));

	worldNormal = normalize(mat3(matWorld) * inNormal);							// BM老实现
	//worldNormal = mat3(transpose_mat4(inverse_mat4(matWorld))) * inNormal;	// 教程版，非优化
	//worldNormal = matNormal * inNormal;										// 新实现，正规矩阵 //todo.shader:最终使用这个

	texCoord = inTexCoord * tillScale;
	texCoordLightMap = inTexCoord1;
	texCoordBatch1 = inTexCoord2;
	texCoordBatch2 = inTexCoord3;

	gl_Position = matVP * vec4(inPosition, 1.0);//matWVP


	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	SHADOW_VS(vec4(inPosition, 1.0));

	vec4 worldPosV4 = matWorld * vec4(inPosition, 1.0);
	FOG_VS(worldPosV4);
}
