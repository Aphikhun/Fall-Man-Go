#version 100

precision mediump float;

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;//vec3->vec2
attribute vec3 inTexCoord1;//vec3->vec2
attribute vec2 inTexCoord2;//batch需要的大图uv
attribute vec2 inTexCoord3;//batch需要的大图uv

uniform highp mat4 matWorld;
uniform highp mat4 matWVP;
uniform highp mat4 matVP;
uniform vec4 fogParam[3];
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec3 subLightDir;
uniform vec4 subLightColor;
uniform mat4 lightSpaceMatrix;
uniform vec3 viewPos;
uniform vec3 scale;
uniform float tillScale;
uniform int unitAisx;
uniform int shapeStyle;

varying vec4 oFogColor;
varying vec2 texCoord;
varying vec3 texCoordLightMap;
varying vec2 texCoordBatch1;
varying vec2 texCoordBatch2;
varying vec3 normal;
varying vec3 vMainViewPos;
varying vec4 FragPosLightSpace;
varying vec3 vMainLightDir;
varying vec4 vMainLightColor;
varying vec3 vertexPos;
varying float ismul;

invariant gl_Position;


float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}

void main(void)
{
	highp vec4 vWorldPos = /* matWorld * */vec4(inPosition, 1.0);
	gl_Position = matVP * vec4(inPosition, 1.0);//matWVP
		
	texCoord = inTexCoord * tillScale;
	texCoordLightMap = inTexCoord1;
	texCoordBatch1 = inTexCoord2;
	texCoordBatch2 = inTexCoord3;
	
	normal = mat3(matWorld) * inNormal;
	vMainViewPos = viewPos;
	vertexPos = vWorldPos.xyz;
	
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));

	FragPosLightSpace = lightSpaceMatrix * vWorldPos;
	vMainLightDir = mainLightDir;
	vMainLightColor = mainLightColor;
}
