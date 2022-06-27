#version 100

#ifdef GL_FRAGMENT_PRECISION_HIGH
	precision highp float;
#else
	precision mediump float;
#endif

attribute highp vec3 inPosition;

uniform mat4 matWVP;
uniform vec4 sectionPos;


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

void main()
{
	vec3 blockPos = inPosition.xyz / 2048.0 + sectionPos.xyz;
	gl_Position = matWVP * vec4(blockPos, 1.0);

#ifndef NEW_FOG
	oFogColor = vec4(fogParam[1].rgb, ComputeFog(blockPos-fogParam[2].xyz, fogParam[0].xyz));
#endif
}
