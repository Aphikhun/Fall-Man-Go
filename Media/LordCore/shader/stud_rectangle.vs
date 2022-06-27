#version 100

attribute highp vec4 inPosition;
attribute vec4 inColor;
attribute vec4 inColor1;

uniform mat4 matWVP;
uniform vec3 cameraPos;

uniform vec4 brightnessColor;

varying vec4 claColor;

const float kDiameter = 0.15 * 2.0;
const float kHeight = 0.1;

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
	vec2 offset = vec2(inColor.a - 0.5, inColor1.a - 0.5) * vec2(kDiameter, kHeight);
    vec4 skyColor = vec4(inColor.rgb, 1.0);
    vec4 blockColor = vec4(inColor1.rgb, 1.0);

	vec3 viewDir = inPosition.xyz - cameraPos;
	vec3 sideDir = normalize(vec3(viewDir.z, 0.0, -viewDir.x));
	vec3 vertex = inPosition.xyz + offset.x * sideDir + vec3(0.0, offset.y, 0.0);
	gl_Position = matWVP * vec4(vertex, 1.0);
	
	
	//to mix fog with blockLightColor
  	float c = max(max(blockColor.r, blockColor.g), blockColor.b);
#ifndef NEW_FOG
	oFogColor = vec4(fogParam[1].rgb, ComputeFog(inPosition.xyz - fogParam[2].xyz, fogParam[0].xyz));
  	oFogColor.rgb = mix(oFogColor.rgb, blockColor.rgb * brightnessColor.rgb, c);
#else
	oBlockColor.rgb = blockColor.rgb * brightnessColor.rgb;
	oBlockColor.a = c;
#endif

  	blockColor.rgb *= brightnessColor.a; // set day or night time
 	vec4 brightnessColor2 = vec4(brightnessColor.rgb, 1.0);
	claColor = blockColor;
}

