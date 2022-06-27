#version 100

attribute highp vec4 inPosition;
attribute vec3 inNormal;
attribute vec4 inColor;
attribute vec2 inTexCoord;
attribute vec2 inTexCoord1;

uniform mat4 matVP;

varying vec3 Normal;
varying vec4 blendines;
varying vec2 texCoord;
varying vec2 texCoord1;
//varying vec2 texCoord2;
varying vec3 oWPos;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

varying vec4 ofogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#endif

void main()
{
	gl_Position = matVP * vec4(inPosition.xyz, 1.0);
    blendines = inColor;
    texCoord = inTexCoord;
    texCoord1 = inTexCoord1;

#ifndef NEW_FOG
	ofogColor = vec4(fogParam[1].rgb, ComputeFog(inPosition.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif
	
	
	oWPos = inPosition.xyz;
	Normal = inNormal;
}

