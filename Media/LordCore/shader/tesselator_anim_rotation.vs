#version 100

attribute highp vec4 inPosition;
attribute vec2 inTexCoord;
attribute vec4 inTexCoord1;
attribute vec4 inColor;

uniform mat4 matWVP;
uniform vec4 sectionPos;
uniform vec4 fogParam;
uniform vec3 cameraPos;
uniform vec2 uvOffset;
uniform vec4 uvRotation;

varying vec4 lightColor;
varying vec4 lightmapUV;
varying vec2 texCoord_texture;
varying float lightStrength;
float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}

void main(void)
{
	vec3 blockPos;
	blockPos = inPosition.xyz / 15.0;
	
	// output position.
	blockPos = sectionPos.xyz + blockPos;
	gl_Position = matWVP * vec4(blockPos, 1.0);

	texCoord_texture = inTexCoord / 32768.0;
	texCoord_texture = texCoord_texture - uvOffset;
	texCoord_texture = texCoord_texture * mat2(uvRotation.x, uvRotation.y, uvRotation.z, uvRotation.w);
	texCoord_texture = texCoord_texture + uvOffset;
	lightmapUV = inTexCoord1 / 255.0;
	lightStrength = inPosition.w/15.0;
	lightColor.xyz = inColor.rgb / 255.0;;
	lightColor.w = ComputeFog(blockPos - cameraPos, fogParam.xyz);
}

