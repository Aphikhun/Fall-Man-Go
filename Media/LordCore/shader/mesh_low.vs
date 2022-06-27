#version 100

attribute highp vec3 inPosition;
attribute vec2 inTexCoord;

uniform mat4 matWorld;
uniform mat4 matWVP;

varying vec2 texCoord;

#ifdef LIGHT_LOW_STATIC_SKINNED
attribute vec3 inNormal;
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec4 ambient;
uniform float ambientStrength;
varying vec3 lightFactor;
#endif

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
	gl_Position = matWVP * vec4(inPosition, 1.0);
		
	texCoord = inTexCoord;

#ifndef NEW_FOG
	oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif

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

}
