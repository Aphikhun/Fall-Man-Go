#version 300 es
precision mediump float;


#include "headers/math/matrix.glsl"												// 教程版会用到
#include "headers/lighting.glsl"
#include "headers/shadow.glsl"

#ifdef USEFOG
#include "headers/fog.glsl"
#endif

#ifndef LOWEFFECT
#include "headers/basic.glsl"
#else
in highp vec3 inPosition;
in vec3 inNormal;
in vec2 inTexCoord;
uniform mat4 matWorld;
uniform mat4 matWVP;
out vec2 texCoord;
out vec3 worldNormal;
out vec3 worldPos;
#endif


uniform mediump vec4 multiCalColor;
uniform float discardAlpha;

out vec4 color;

#ifndef LOWEFFECT
out vec3 normal;
#else
out vec3 lightFactor;
out float vDiscardAlpha;
#endif

out float useOverlayColorReplaceMode;

invariant gl_Position;


void main(void)
{
#ifndef LOWEFFECT
	vec4 vWorldPos = matWorld * inPosition;
	gl_Position = matWVP * inPosition;
#else
	vec4 vWorldPos = matWorld * vec4(inPosition, 1.0);
	gl_Position = matWVP * vec4(inPosition, 1.0);
#endif
	
	texCoord = inTexCoord;
	
#ifndef LOWEFFECT
	#ifndef TRANSPARENT
		// vec3 vNorm = normalize(mat3(matWorld) * inNormal);
		
		// float mainParam = max(dot(mainLightDir, vNorm), 0.0);
		// float subParam = max(dot(subLightDir, vNorm), 0.0);

		// normal = vNorm;
		
		// color = mainParam * mainLightColor + subParam * subLightColor + ambient;
		// color.a = 1.0;
		// color.rgb = color.rgb * multiCalColor.rgb;

		// FragPosLightSpace = lightSpaceMatrix * vWorldPos;
		// vMainLightDir = mainLightDir;
		// vMainLightColor = mainLightColor;
		
		// worldNormal = normalize(mat3(matWorld) * inNormal);	
		SHADOW_VS(inPosition);
		#ifdef USEFOG
			FOG_VS(vWorldPos);
		#endif

	#else 
		color = multiCalColor;
		color.a = inNormal.x * inNormal.x * 0.00001;
		// color.a += inNormal.x * 0.00001;
		vDiscardAlpha = discardAlpha;
	#endif
#else
	#ifdef LIGHT_LOW_STATIC_SKINNED
		// Ambient
		mediump float ambientStrength = 0.6;
		mediump vec3 ambient = ambientStrength * mainLightColor.rgb;
		
		// Diffuse 
		mediump vec3 norm = normalize(mat3(matWorld) * inNormal);
		mediump vec3 lightDir = normalize(mainLightDir);
		mediump float diff = max(dot(norm, lightDir), 0.0);
		mediump vec3 diffuse = diff * mainLightColor.rgb;

		lightFactor = ambient + diffuse/* + specular*/;
	#endif
#endif

	worldNormal = normalize(mat3(matWorld) * inNormal);	
	worldPos =  vec3(vWorldPos);
#ifdef USEFOG
#ifndef NEW_FOG
	fogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif
#endif

	useOverlayColorReplaceMode = multiCalColor.a;
}
