#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;

uniform mat4 matWorld;
uniform mat4 matWVP;
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec3 subLightDir;
uniform vec4 subLightColor;
uniform vec4 ambient;
uniform mat4 lightSpaceMatrix;
uniform mediump vec4 multiCalColor;

varying vec4 color;
varying vec2 texCoord;
varying vec3 normal;
varying float useOverlayColorReplaceMode;

invariant gl_Position;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

#endif

void main(void)
{
	vec4 vWorldPos = matWorld * vec4(inPosition, 1.0);
	gl_Position = matWVP * vec4(inPosition, 1.0);
		
	texCoord = inTexCoord;
	
	vec3 vNorm = normalize(mat3(matWorld) * inNormal);

	normal = vNorm;
	
	color = ambient;
	color.a = 1.0;
	color.rgb = color.rgb * multiCalColor.rgb;
	color.rgb = vec3(1.0,1.0,1.0);
	
	useOverlayColorReplaceMode = multiCalColor.a;
}
