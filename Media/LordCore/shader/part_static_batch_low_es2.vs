#version 100    

attribute highp vec3 inPosition;    // xyz:  世界空间位置
attribute vec2 inTexCoord;          // xy:   纹理坐标
attribute vec4 inNormal;            // xyz:  法线(0~255)        w: 材质
attribute vec4 inColor;             // rgba: 0~255

uniform highp mat4 matViewProj;
uniform mediump mat4 matLightSapce;
uniform mediump vec4 fogParam[3];
uniform mediump vec3 uViewPosition;
uniform mediump vec3 uLightDirection;
uniform mediump vec4 uLightStrength;
uniform mediump vec4 uAmbientStrength;
uniform mediump float uAmbientFactor;
uniform mediump vec2 uMaterialLayer[24];    // xy 图集上对应材质的初始纹理位置

#ifdef BLOCKMAN_EDITOR
    uniform mediump mat4 matModel;
#endif

mediump vec4 getUV(int matIndex)
{
    vec2 offset = uMaterialLayer[matIndex];
    return vec4(inTexCoord, offset);
}

mediump float ComputeFog(vec3 camToWorldPos, vec3 param) {
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}

varying mediump vec4 ourTexcoord;
varying mediump vec4 ourColor;
varying mediump vec3 ourLightFactor;
varying mediump vec4 ourFogColor;

void main() 
{
    ourTexcoord = getUV(int(inNormal.w));
    ourColor    = inColor.rgba * (1.0 / 255.0);

    highp vec4 worldPosition = vec4(inPosition, 1.0);
//just use in editor - by chentiansheng
#ifdef BLOCKMAN_EDITOR
    worldPosition = matModel * worldPosition;
#endif

	gl_Position = matViewProj * worldPosition;

    // Fog
    mediump float fogAlpha = ComputeFog(worldPosition.xyz - fogParam[2].xyz, fogParam[0].xyz);
    ourFogColor = vec4(fogParam[1].rgb, fogAlpha);
	
    // Ambient
    mediump vec3 ambient = uAmbientStrength.rgb * uAmbientFactor;
  	
    // Diffuse 
    mediump vec3 N = inNormal.xyz * (2.0 / 255.0) - 1.0;
    mediump vec3 L = uLightDirection;
    mediump float NdotL = max(dot(N, L), 0.0);
    mediump vec3 diffuse = NdotL * uLightStrength.rgb;

    // Specular
    mediump vec3 specular = vec3(0.0);
    mediump float specularStrength = 0.5;
    mediump vec3 V = normalize(uViewPosition - worldPosition.xyz);
    mediump vec3 R = reflect(-V, N);
	mediump float RdotV = max(dot(R, V), 0.0);
    mediump float spec = RdotV * RdotV * RdotV * RdotV;
	spec = spec * spec;
	spec = spec * spec;
	spec = spec * spec;
    specular = specularStrength * spec * uLightStrength.rgb;
	ourLightFactor = ambient + diffuse + specular;
}