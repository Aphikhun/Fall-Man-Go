#version 100
attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord;

uniform mat4 matWorld;
uniform mat4 matView;
uniform mat4 matProj;
uniform float scale;
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec3 viewPos;

varying vec2 texCoord;
varying vec3 lightFactor;

void main(void)
{
    texCoord = inTexCoord;
	mat3 worldMatrix = mat3(matWorld);
	vec3 pos = worldMatrix * (scale * inPosition);
    
    // ambient
    vec3 ambient = 0.5 * mainLightColor.rgb;
    // diffuse
    vec3 lightDir = normalize(mainLightDir);
	vec3 normal = normalize(worldMatrix * inNormal);
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = 0.5 * diff * mainLightColor.rgb;
    // specular
    vec3 viewDir = normalize(viewPos - pos);
    vec3 reflectDir = reflect(-lightDir, normal);
	float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
    vec3 specular = 0.5 * spec * mainLightColor.rgb;

	lightFactor = ambient + diffuse + specular;

	gl_Position = matProj * matView * matWorld * vec4(scale * inPosition, 1.0);
}