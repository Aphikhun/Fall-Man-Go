#version 300 es

layout(location = 0) in highp vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec3 inTexCoord;
layout(location = 3) in vec3 inTexCoord2;
layout(location = 4) in mat4 inGpuInstanceMat;
layout(location = 8) in vec4 inColor;

uniform mat4 matWorld;
uniform mat4 matWVP;
uniform mat4 matVP;
uniform vec4 fogParam[3];
uniform vec3 mainLightDir;
uniform vec4 mainLightColor;
uniform vec3 subLightDir;
uniform vec4 subLightColor;
uniform vec4 ambient;
uniform mat4 lightSpaceMatrix;
uniform vec4 multiCalColor;
uniform vec3 viewPos;
uniform vec3 scale;
uniform float isCube;
uniform int unitAisx;
uniform int shapeStyle;
uniform mediump float useGPUInstance;

out vec4 gpuinstanceColor;
out vec4 color;
out vec2 texCoord;
out vec3 lightFactor;
out float useOverlayColorReplaceMode;

invariant gl_Position;

void main(void)
{
    mat4 vRealMatWorld = (useGPUInstance > 0.9 ? inGpuInstanceMat : matWorld);
	vec4 vWorldPos = vRealMatWorld * vec4(inPosition, 1.0);
	gl_Position = matVP * vRealMatWorld * vec4(inPosition, 1.0);
		
	vec3 N = abs(inNormal);
	vec3 tex3 = (inPosition + 0.5) * scale;
	vec2 texcoordCube = (N.x > 0.99 ? tex3.zy : (N.y > 0.99 ? tex3.zx : tex3.xy));
	texcoordCube.x = 1.0- texcoordCube.x;
	vec2 texcoordUnion = (inTexCoord * scale).xy;
	vec2 texcoord1 = N.y > 0.99 ? tex3.zx : (inTexCoord * scale).xy;
	//texCoord = (isCube == 1.0) ? texcoordCube : (isCube == 0.0 ? texcoordUnion : texcoord1);
	texCoord = (isCube == 0.0) ? texcoordUnion : texcoord1;
	
    gpuinstanceColor = inColor;
	color = vec4(multiCalColor.rgb, 1.0);
	useOverlayColorReplaceMode = multiCalColor.a;
	
    // Ambient
    mediump float ambientStrength = 0.6;
    mediump vec3 ambient = ambientStrength * mainLightColor.rgb;
  	
    // Diffuse 
    mediump vec3 norm = normalize(mat3(vRealMatWorld) * inNormal);
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
