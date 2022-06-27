#version 100

attribute highp vec3 inPosition;
attribute vec2 inTexCoord;
attribute vec2 inTexCoord1;

uniform mat4 matWVP;
uniform vec3 cameraPos;

varying vec2 texCoord;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

varying vec4 oFogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#endif

void main(void)
{
	vec3 viewDir = inPosition.xyz - cameraPos;
	vec3 sideDir = normalize(vec3(viewDir.z, 0.0, -viewDir.x));
	vec3 vertex = inPosition.xyz + inTexCoord.x * sideDir + vec3(0.0, inTexCoord.y, 0.0);
	gl_Position = matWVP * vec4(vertex, 1.0);

#ifndef NEW_FOG
	oFogColor = vec4(fogParam[1].rgb, ComputeFog(inPosition.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif

	texCoord = inTexCoord1;
}