#version 100

attribute highp vec3 inPosition;
attribute vec3 inTexCoord;

uniform mat4 matWorld;
uniform mat4 matWVP;

uniform mat4 merge_worldProj[20]
uniform mat4 merge_viewProj

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

invariant gl_Position;

void main(void)
{
	float matWorldIndex = inTexCoord.z
	mat4  curMatWorld = merge_worldProj[int(matWorldIndex)]
	vec4 vWorldPos = curMatWorld * vec4(inPosition, 1.0);
	gl_Position = merge_viewProj * vWorldPos;
		
	texCoord = inTexCoord;

#ifndef NEW_FOG
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif
}
