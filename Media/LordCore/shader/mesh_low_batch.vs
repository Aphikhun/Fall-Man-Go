#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;
attribute vec2 inTexCoord2;
attribute vec2 inTexCoord3;

uniform mat4 matWorld;
uniform mat4 matVP;
uniform mat4 matWVP;
//uniform mediump vec4 multiCalColor;

varying vec2 texCoord;
varying vec2 texCoordBatch1;
varying vec2 texCoordBatch2;
//varying float useOverlayColorReplaceMode;

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
	vec4 vWorldPos = matWorld * vec4(inPosition, 1.0);
	gl_Position = matVP * vec4(inPosition, 1.0); //matWVP
		
	texCoord = inTexCoord;
	texCoordBatch1 = inTexCoord2;
	texCoordBatch2 = inTexCoord3;

#ifndef NEW_FOG
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
	oFogColor.a += inNormal.x*0.000001;
#endif
	
	//useOverlayColorReplaceMode = multiCalColor.a;
}
