#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;

uniform mat4 matWorld;
uniform mat4 matVP;
uniform mat4 matWVP;
uniform vec4 fogParam[3];
uniform mediump vec4 multiCalColor;
uniform vec4 alphaColor;
uniform float discardAlpha;

varying vec4 oFogColor;
varying vec2 texCoord;
varying vec4 color;
varying float vDiscardAlpha;
varying float useOverlayColorReplaceMode;

invariant gl_Position;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}

void main(void)
{
	vec4 vWorldPos = matWorld * vec4(inPosition, 1.0);
	gl_Position = matVP * vec4(inPosition, 1.0);
		
	texCoord = inTexCoord;

	color = multiCalColor;
	color.a = alphaColor.a;
	color.a += inNormal.x*0.00001;
	
	vDiscardAlpha = discardAlpha;
	
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));

	useOverlayColorReplaceMode = multiCalColor.a;
}
