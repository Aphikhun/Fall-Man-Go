#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec3 inTexCoord;
attribute vec2 inTexCoord1;
attribute vec3 inTexCoord2;

uniform highp mat4 matWorld;
uniform highp mat4 matWVP;
uniform vec4 fogParam[3];
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec4 ambientColor;
uniform mediump float ambientStrength;
uniform vec3 subLightDir;
uniform vec4 subLightColor;
uniform mat4 lightSpaceMatrix;
uniform vec3 viewPos;
uniform vec3 scale;
uniform float tillScale;
uniform int unitAisx;
uniform int shapeStyle;

varying vec4 oFogColor;
varying vec2 texCoord;
varying vec3 lightFactor;
varying vec2 lightMapUV;

invariant gl_Position;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}

void main(void)
{
	highp vec4 vWorldPos = matWorld * vec4(inPosition, 1.0);
	gl_Position = matWVP * vec4(inPosition, 1.0);

    texCoord = vec2(inTexCoord) * scale.xy;
    lightMapUV = inTexCoord1.xy;

    // Fog
    oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
	
    // Ambient
    mediump vec3 ambient = ambientStrength * ambientColor.rgb;
  	
    // Diffuse 
    mediump vec3 norm = normalize(mat3(matWorld) * inNormal);
    mediump vec3 lightDir = normalize(mainLightDir);
    mediump float diff = max(dot(norm, lightDir), 0.0);
    mediump vec3 diffuse = diff * mainLightColor.rgb;

    // Specular
    mediump vec3 specular = vec3(0.0);
    mediump float specularStrength = 0.0;
    mediump vec3 viewDir = normalize(viewPos - vWorldPos.xyz);
    mediump vec3 reflectDir = reflect(-lightDir, norm);
	float specSrc = max(dot(viewDir, reflectDir), 0.0);
    mediump float spec = specSrc * specSrc * specSrc * specSrc;
	spec = spec * spec;
	spec = spec * spec;
	spec = spec * spec;
    specular = specularStrength * spec * mainLightColor.rgb;
	lightFactor = ambient + diffuse + specular;
}
