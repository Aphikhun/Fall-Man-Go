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
layout(location = 2) in vec3 inTexCoord;
layout(location = 3) in vec3 inTexCoord1;
layout(location = 4) in vec3 inTexCoord2;
layout(location = 5) in mat4 inGpuInstanceMat;
layout(location = 9) in vec4 inColor;

uniform highp mat4 matWorld;
uniform highp mat4 matVP;

out highp vec3 worldPos;
out vec3 worldNormal;
out vec2 texCoord;
out vec2 lightMapUV;

uniform vec3 scale;

uniform mediump float useGPUInstance;
out vec4 gpuinstanceColor;


invariant gl_Position;
////////////////////////////////////////////////////


void main(void)
{
	worldPos = inPosition;

	worldNormal = normalize(inNormal);							// BM老实现
	//worldNormal = mat3(transpose_mat4(inverse_mat4(matWorld))) * inNormal;	// 教程版，非优化
	//worldNormal = matNormal * inNormal;										// 新实现，正规矩阵 //todo.shader:最终使用这个
	
    texCoord = vec2(inTexCoord);
	lightMapUV = inTexCoord1.xy;

	gl_Position = matVP * vec4(inPosition, 1.0);


	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	SHADOW_VS(vec4(inPosition, 1.0));

	vec4 worldPosV4 = vec4(inPosition, 1.0);
	FOG_VS(worldPosV4);
	
	//装饰
	gpuinstanceColor = inColor;
}
