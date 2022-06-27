#version 300 es

// mesh data
layout(location = 0) in highp vec3  inPosition;
layout(location = 1) in vec3  inNormal;
layout(location = 2) in vec2  inTexCoord;
// instance data
layout(location = 3) in mat4  inMatWorld;
layout(location = 7) in vec3  inTexcoordScale;
layout(location = 8) in float inMaterialIndex;
layout(location = 9) in vec4  inColor;

uniform float isCube;
uniform mat4 matViewProj;
uniform vec4 fogParam[3];
uniform vec3 uViewPosition;
uniform vec3 uLightDirection;
uniform vec4 uLightStrength;
uniform vec4 uAmbientStrength;
uniform float uAmbientFactor;


vec2 CalcTexcoord() {
    vec3 N = abs(inNormal);
    vec3 tex3 = (inPosition + 0.5) * inTexcoordScale;
	vec2 texcoordCube = (N.x > 0.99 ? tex3.zy : (N.y > 0.99 ? tex3.zx : tex3.xy));
	texcoordCube.x = 1.0- texcoordCube.x;
	vec2 texcoordUnion = inTexCoord * inTexcoordScale.xy;
	vec2 texcoord1 = N.y > 0.99 ? tex3.zx : inTexCoord * inTexcoordScale.xy;
	return (isCube == 1.0) ? texcoordCube : (isCube == 0.0 ? texcoordUnion : texcoord1);
}

float ComputeFog(vec3 camToWorldPos, vec3 param) {
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}

out highp vec2  ourTexcoord;
out vec4  ourColor;
out vec3  ourLightFactor;
out float ourMaterialIndex; 
out vec4  ourFogColor;

void main() {
	vec4 worldPosition = inMatWorld * vec4(inPosition, 1.0);
	gl_Position = matViewProj * worldPosition;

    ourTexcoord = CalcTexcoord();
    ourColor = inColor * (1.0 / 255.0);;
    ourMaterialIndex = (inMaterialIndex + 0.5);

    // Fog
    ourFogColor =  vec4(fogParam[1].rgb, ComputeFog(worldPosition.xyz - fogParam[2].xyz, fogParam[0].xyz));
	
    // Ambient
    mediump vec3 ambient = uAmbientStrength.rgb * uAmbientFactor;
  	
    // Diffuse 
    mediump vec3 N = normalize(inNormal);
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