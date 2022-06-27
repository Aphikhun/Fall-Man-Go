#version 100

attribute highp vec3 inPosition;

uniform mat4 matWVP;
uniform vec4 inColor;

varying vec4 color;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#endif

void main(void)
{
#ifndef NEW_FOG
	vec4 oFogColor = vec4(fogParam[1].rgb, ComputeFog(inPosition-fogParam[2].xyz, fogParam[0].xyz));
	color = vec4(mix(oFogColor.rgb, inColor.rgb, oFogColor.a), 1.0);
#else
	color = vec4(inColor.rgb, 1.0);
#endif
	
	gl_Position = matWVP * vec4(inPosition, 1.0);
}