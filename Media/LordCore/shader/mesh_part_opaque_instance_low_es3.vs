#version 300 es
// mesh data
layout(location = 0) in highp vec3  inPosition;
layout(location = 1) in vec3  inNormal;
layout(location = 2) in vec3  inTexCoord;
// instance data
layout(location = 3)  in mat4  inMatWorld;
layout(location = 7)  in vec4  inNaturalColor;
layout(location = 8)  in vec4  inCustomColor;
layout(location = 9)  in vec4  inSubMeshColor;
layout(location = 10) in vec4  inMultiCalColor;
layout(location = 11) in vec4  inParame0;               // .xyz:inUvParam           .w:inDiscardAlpha 
layout(location = 12) in vec4  inParame1;               // .xyz:inSubMeshUVParam    .w:inAlpha
layout(location = 13) in vec4  inParame2;               // .x:inIsSubMesh .y:inCustomThreshold .z:inUseTextureAlpha .w: inSubMeshAlpha
layout(location = 14) in vec4  inParame3;               // .xyz: subMeshOffsetParam
 
uniform mat4 matViewProj;
uniform vec4 fogParam[3];
uniform mediump vec3 uViewPosition;
uniform vec3 uLightDirection;
uniform vec4 uLightStrength;
uniform vec4 uAmbientStrength;
uniform float uAmbientFactor;

out vec3 ourLightFactor;
out vec4 ourFogColor;
out vec2 ourTexcoord;
out vec4 ourNaturalColor;
out vec4 ourCustomColor;
out vec4 ourSubMeshColor;
out vec4 ourMultiCalColor;
out vec4 ourParame0;               // .xyz:inUvParam           .w:inDiscardAlpha 
out vec4 ourParame1;               // .xyz:inSubMeshUVParam    .w:inAlpha
out vec4 ourParame2;               // .x:inIsSubMesh .y:inCustomThreshold .z:inUseTextureAlpha
out vec4 ourParame3;               // .xyz: subMeshOffsetParam

float ComputeFog(vec3 camToWorldPos, vec3 param) {
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}

void main() {
    vec4 worldPosition = inMatWorld * vec4(inPosition, 1.0);
    gl_Position = matViewProj * worldPosition;
    ourTexcoord = inTexCoord.xy;
    ourNaturalColor = inNaturalColor;
    ourCustomColor = inCustomColor;
    ourSubMeshColor = inSubMeshColor;
    ourMultiCalColor = inMultiCalColor;
    ourParame0 = inParame0;
    ourParame1 = inParame1;
    ourParame2 = inParame2;
    ourParame3 = inParame3;

    // Fog
    ourFogColor =  vec4(fogParam[1].rgb, ComputeFog(worldPosition.xyz - fogParam[2].xyz, fogParam[0].xyz));
	
    // Ambient
    mediump vec3 ambient = uAmbientStrength.rgb * uAmbientFactor;
  	
    // Diffuse 
    vec3 N = normalize((transpose(inverse(inMatWorld)) * vec4(inNormal, 0.0)).xyz);
    mediump vec3 L = uLightDirection;
    mediump float NdotL = max(dot(N, L), 0.0);
    mediump vec3 diffuse = NdotL * uLightStrength.rgb;

    // Specular
    mediump vec3 specular = vec3(0.0);
    mediump float specularStrength = 0.5;
    mediump vec3 V = normalize(uViewPosition - worldPosition.xyz);
    mediump vec3 R = reflect(-V, N);
	float RdotV = max(dot(R, V), 0.0);
    mediump float spec = RdotV * RdotV * RdotV * RdotV;
	spec = spec * spec;
	spec = spec * spec;
	spec = spec * spec;
    specular = specularStrength * spec * uLightStrength.rgb;
	ourLightFactor = ambient + diffuse + specular;
}