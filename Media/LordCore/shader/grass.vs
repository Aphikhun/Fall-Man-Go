#version 100

attribute highp vec3 inPosition;
attribute vec3 inTexCoord;
attribute vec3 inTexCoord2;	// WorldPos
attribute vec2 inNormal;
attribute vec3 inTexCoord1;
attribute vec4 inColor;

uniform vec4	c_GrassWindPosition;
uniform vec4	c_GrassWindParam;
uniform vec3	c_GrassWindSpeed;
uniform vec3	c_GrassUSScale;
uniform mat4 	matVP;		// VP
uniform vec3	fogPos;
uniform vec4	litParam[3];
uniform vec3	camPos;


varying vec2 	texCoord;
varying vec4	verColor;
varying vec3	transColor;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

varying vec4 fogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#endif

float SmoothCurve( float x )
{
	return x * x * (3.0-2.0*x);
}

float TriangleWave( float x )
{
	return abs( fract(x+0.5)*2.0 - 1.0 );
} 

float SmoothTriangleWave( float x )
{
	return  SmoothCurve( TriangleWave(x) );
}

vec3 Translucency(vec3 vColor, vec3 vLight, vec3 vEye, vec3 vNormal)
{
	vec3 fLTAmbient = vColor;
	float fLightAttenuation = 1.0;
	float fLTDistortion = 0.2; // 0 ~ 0.2;
	float fLTScale = 1.0; // 1 ~ 5
	float iLTPower = 12.0; // 4 ~ 12

	vec3 vLTLight = vLight + vNormal * fLTDistortion;
	float fLTDot = pow(clamp(dot(vEye, -vLTLight), 0.0, 1.0), iLTPower) * fLTScale;
	vec3 fLT = fLightAttenuation * fLTDot * fLTAmbient;
	return fLT;
}

void main(void)
{
	// 1. Calculate the local waved position:
	float scale = inNormal.x;
	float angle = inNormal.y;
	float radiansAngle = radians(angle);
	float cosAngle = cos(radiansAngle);
	float sinAngle = sin(radiansAngle);

	mat4 matInW = mat4(scale * cosAngle,	0.0,			-scale * sinAngle,	0.0,
						0.0, 				scale, 			0.0, 				0.0,
						scale * sinAngle, 	0.0, 			scale * cosAngle, 	0.0,
						inTexCoord2.x, 		inTexCoord2.y,	inTexCoord2.z, 		1.0);
						
	vec4 windDir = vec4(inTexCoord2, 1.0) - c_GrassWindPosition;
	float dis = length(windDir.xyz);
	//windDir = matInW * windDir;
	vec3 windDirN = normalize(windDir.xyz);
	float moved = (SmoothTriangleWave(dis/c_GrassWindParam.x+c_GrassWindParam.z*c_GrassWindSpeed.x * 2.0)+c_GrassWindParam.y)*c_GrassWindParam.w;
	float delta = dot(windDirN, vec3(0.0, 0.0, 1.0)) * inTexCoord.z * moved;

	vec4 pos = vec4(inPosition, 1.0);
	vec3 worldPos = (matInW*pos).xyz;
	worldPos = worldPos + windDirN * delta * vec3(1.0, -1.0 * inTexCoord1.z, 1.0);

	gl_Position = matVP * vec4(worldPos, 1.0);
	
	vec2 uvScale_t = vec2(c_GrassUSScale.x, c_GrassUSScale.y * inTexCoord1.z);
	texCoord = (inTexCoord.xy + inTexCoord1.xy + 0.02) * uvScale_t.xy;

	verColor = inColor;
	vec3 normal = vec3(0.0, 1.0, 0.0) - windDirN * delta * scale * 2.0;
	normal = normalize(normal);
	vec3 viewDir = normalize(camPos - worldPos.xyz);
	transColor = Translucency(litParam[1].rgb, litParam[0].xyz, viewDir, normal);
	// Fog color.
	
#ifndef NEW_FOG
	fogColor =  vec4(fogParam[1].rgb, ComputeFog(worldPos.xyz - fogParam[2].xyz, fogParam[0].xyz));
#endif
}