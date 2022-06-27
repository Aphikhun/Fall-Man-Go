#version 100

attribute highp vec4 inPosition;
attribute vec2 inTexCoord;
attribute vec4 inColor1;
attribute vec4 inColor;
attribute vec4 inNormal;

uniform vec3 lightDir;
uniform vec4 lightColor;
uniform vec4 brightnessColor;
uniform mat4 matWVP;
uniform vec4 sectionPos;
uniform mat4 lightSpaceMatrix;
uniform vec3 viewPos;
uniform float useSpecularAndIntensity;

varying vec3 oNormal;
varying vec4 claColor;
varying vec4 specularColor;
varying vec2 texCoord_texture;
varying vec4 FragPosLightSpace;
varying vec3 mainlightDir;
varying vec4 uBrightnessColor;

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
  mainlightDir = lightDir;
  //specular
  mediump float Gloss = 12.65;
  mediump vec3 viewDir = normalize(viewPos - blockPos);
  //Phong
  //Blinn-Phong     
  mediump vec3 halfDir = normalize(lightDir + viewDir);
  mediump float spec = pow(max(dot(oNormal, halfDir), 0.0), Gloss);
  specularColor.rgb = useSpecularAndIntensity * spec * lightColor.rgb * vec3(0.9,0.95,0.99);

  uBrightnessColor = brightnessColor;
}

