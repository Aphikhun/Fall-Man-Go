#version 100

precision mediump float;

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;//vec3->vec2
attribute vec3 inTexCoord1;//vec3->vec2
//attribute vec3 inTexCoord2;
attribute vec2 inTexCoord2;//batch需要的大图uv
attribute vec2 inTexCoord3;//batch需要的大图uv

uniform highp mat4 matWorld;
uniform highp mat4 matWVP;
uniform highp mat4 matVP;
uniform vec4 fogParam[3];
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec4 ambientColor;
uniform float ambientStrength;
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
varying vec3 texCoordLightMap;
varying vec2 texCoordBatch1;
varying vec2 texCoordBatch2;
varying vec3 lightFactor;

invariant gl_Position;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}

void main(void)
{
    highp vec4 vWorldPos = /* matWorld * */vec4(inPosition, 1.0);
	gl_Position = matVP * vec4(inPosition, 1.0);//matWVP

    texCoord = inTexCoord * tillScale;
    texCoordLightMap = inTexCoord1;
	texCoordBatch1 = inTexCoord2;
	texCoordBatch2 = inTexCoord3;

    // Fog
    oFogColor =  vec4(fogParam[1].rgb, ComputeFog(vWorldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
	
    // Ambient
    mediump vec3 ambient = ambientStrength * ambientColor.rgb;
  	
    // Diffuse 
    mediump vec3 norm = normalize(/*mat3(matWorld) * */inNormal); 
    mediump vec3 lightDir = normalize(mainLightDir);
    mediump float diff = max(dot(norm, lightDir), 0.0);
    mediump vec3 diffuse = diff * mainLightColor.rgb;

    // Specular
    mediump vec3 specular = vec3(0.0);
    mediump float specularStrength = 0.5;
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
