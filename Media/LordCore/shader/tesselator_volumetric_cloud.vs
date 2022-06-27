#version 100

attribute highp vec3 inPosition;

uniform mat4 matWorld;
uniform mat4 matWVP;

varying vec4 worldPos;

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
	worldPos = matWorld * vec4(inPosition, 1.0);

	gl_Position = matWVP * worldPos;

#ifndef NEW_FOG
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(worldPos.xyz-fogParam[2].xyz, fogParam[0].xyz));
#endif
}
