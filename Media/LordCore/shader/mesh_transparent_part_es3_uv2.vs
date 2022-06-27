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
uniform highp mat4 matWVP;
uniform highp mat4 matVP;
//uniform mat4 matNormal;//正规矩阵，防止平移或非等比缩放 对 normal的破坏。https://learnopengl-cn.readthedocs.io/zh/latest/02%20Lighting/02%20Basic%20Lighting/

out highp vec3 worldPos;
out vec3 worldNormal;
out vec2 texCoord;
out vec2 lightMapUV;

uniform vec3 scale;
uniform float tillScale;
uniform float isCube;

uniform mediump float useGPUInstance;
out vec4 gpuinstanceColor;


invariant gl_Position;
////////////////////////////////////////////////////


void main(void)
{
	mat4 vRealMatWorld = (useGPUInstance > 0.9 ? inGpuInstanceMat : matWorld);
	worldPos = vec3(matWorld * vec4(inPosition, 1.0));

	worldNormal = normalize(mat3(matWorld) * inNormal);							// BM老实现
	//worldNormal = mat3(transpose_mat4(inverse_mat4(matWorld))) * inNormal;	// 教程版，非优化
	//worldNormal = matNormal * inNormal;										// 新实现，正规矩阵 //todo.shader:最终使用这个
	
	vec3 N = abs(inNormal);
	vec3 tex3 = (inPosition + 0.5) * scale;
	vec2 texcoordCube = (N.x > 0.99 ? tex3.zy : (N.y > 0.99 ? tex3.zx : tex3.xy));
	texcoordCube.x = 1.0- texcoordCube.x;
	vec2 texcoordUnion = (inTexCoord * scale * tillScale).xy;
	vec2 texcoord1 = N.y > 0.99 ? tex3.zx : (inTexCoord * scale * tillScale).xy;
	//texCoord = (isCube == 1.0) ? texcoordCube : (isCube == 0.0 ? texcoordUnion : texcoord1);
	texCoord = (isCube == 0.0) ? texcoordUnion : texcoord1;

	lightMapUV = inTexCoord1.xy;

	//gl_Position = matWVP * vec4(inPosition, 1.0);
	gl_Position = matVP * vRealMatWorld * vec4(inPosition, 1.0);


	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	SHADOW_VS(vec4(inPosition, 1.0));

	vec4 worldPosV4 = matWorld * vec4(inPosition, 1.0);
	FOG_VS(worldPosV4);
	
	//装饰
	gpuinstanceColor = inColor;
}
