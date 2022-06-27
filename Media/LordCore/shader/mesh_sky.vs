#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;

uniform mat4 matWVP;
uniform mat4 matWorld;
uniform mediump vec4 multiCalColor;
uniform vec3 viewPos;

varying vec4 color;
varying vec2 texCoord;
varying vec3 normal;
varying vec3 viewDir;

invariant gl_Position;

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
	vec4 vWorldPos = matWorld * vec4(inPosition, 1.0);
	gl_Position = matWVP * vec4(inPosition, 1.0);

	texCoord = inTexCoord;
	normal = normalize(mat3(matWorld) * inNormal);
	viewDir = viewPos - vWorldPos.xyz;

	color = multiCalColor;
	color.a = 1.0;
#ifndef NEW_FOG
	oFogColor = vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif
}
