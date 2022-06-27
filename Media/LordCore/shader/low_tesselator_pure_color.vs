#version 100

attribute highp vec4 inPosition;
attribute vec4 inColor1;
attribute vec4 inColor;

uniform mat4 matWVP;
uniform vec4 sectionPos;
uniform vec4 brightnessColor;

varying vec4 claColor;

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
}

