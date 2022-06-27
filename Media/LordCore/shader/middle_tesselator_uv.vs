#version 100

attribute highp vec4 inPosition;
attribute vec2 inTexCoord;
attribute vec4 inColor1;
attribute vec4 inColor;
attribute vec4 inNormal;

uniform vec4 uvTime;
uniform vec4 brightnessColor;
uniform mat4 matWVP;
uniform vec4 sectionPos;
uniform mat4 lightSpaceMatrix;

varying vec3 oNormal;
varying vec4 claColor;
varying vec2 texCoord_texture;
varying vec4 FragPosLightSpace;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

varying vec4 oFogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#else
varying vec4 oBlockColor;
#endif

void main(void)
{
	texCoord_texture = inTexCoord / 2048.0;
	texCoord_texture = texCoord_texture + vec2(uvTime.xy * uvTime.zw);

	oNormal = inNormal.xyz / 127.0 - 1.0;
	oNormal = normalize(oNormal);

	vec3 blockPos = inPosition.xyz / 2048.0;	
	vec4 blockColor = inColor / 255.0;

	blockPos = sectionPos.xyz + blockPos;
	gl_Position = matWVP * vec4(blockPos, 1.0);

	vec4 pbrColor = inColor1 / 255.0;

	//to mix fog with blockLightColor
  	float mixval = mod(inPosition.w / 256.0 , 2.0)/ 10.0;
  	float c = max(max(blockColor.r, blockColor.g), blockColor.b) * mixval;
#ifndef NEW_FOG
	oFogColor = vec4(fogParam[1].rgb, ComputeFog(blockPos-fogParam[2].xyz, fogParam[0].xyz));
	oFogColor.rgb = mix(oFogColor.rgb, blockColor.rgb * brightnessColor.rgb, c);
#else
    oBlockColor.rgb = blockColor.rgb * brightnessColor.rgb;
    oBlockColor.a = c;
#endif
  	

  	float colorScale = mod(inPosition.w, 256.0) / 2.0 / 10.0;
  	float emissionScale = inPosition.w / 256.0 / 2.0 / 10.0;
  	blockColor *= brightnessColor.a; // set day or nite time
  	vec4 brightnessColor2 = vec4(brightnessColor.rgb, 1.0);
  	claColor = pbrColor * brightnessColor2 * colorScale + blockColor * emissionScale;

    FragPosLightSpace = lightSpaceMatrix * vec4(blockPos, 1.0);
}

