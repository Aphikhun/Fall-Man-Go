#version 300 es

in highp vec4 inPosition;
in vec2 inTexCoord;
in vec4 inColor1;
in vec4 inColor;
in vec2 inTexIndex;

uniform vec4 brightnessColor;
uniform mat4 matWVP;
uniform vec4 sectionPos;

out vec4 claColor;
out vec2 texCoord_texture;
out float oTexIndex;


#ifndef NEW_FOG
uniform vec4 fogParam[3];

out vec4 oFogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#endif

void main(void)
{	
  texCoord_texture = inTexCoord / 2048.0;

  vec3 blockPos = inPosition.xyz / 2048.0;  
  vec4 blockColor = inColor / 255.0;

  blockPos = sectionPos.xyz + blockPos;
  gl_Position = matWVP * vec4(blockPos, 1.0);

  vec4 pbrColor = inColor1 / 255.0;

#ifndef NEW_FOG
  oFogColor = vec4(fogParam[1].rgb, ComputeFog(blockPos-fogParam[2].xyz, fogParam[0].xyz));
#endif

  //to mix fog with blockLightColor
  float mixval = inPosition.w / 256.0 / 10.0;
  float c = max(max(pbrColor.r, pbrColor.g), pbrColor.b) * mixval;
  oFogColor.rgb = mix(oFogColor.rgb, pbrColor.rgb * brightnessColor.rgb, c);

  float colorScale = mod(inPosition.w, 256.0) / 2.0 / 10.0;
  claColor = (pbrColor * brightnessColor + blockColor) * colorScale;

  oTexIndex = inTexIndex.x;
}

