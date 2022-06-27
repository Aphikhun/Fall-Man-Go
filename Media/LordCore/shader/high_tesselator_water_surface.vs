#version 100

#ifdef GL_FRAGMENT_PRECISION_HIGH
	precision highp float;
#else
	precision mediump float;
#endif

attribute highp vec3 inPosition;

uniform mat4 matWVP;
uniform vec4 sectionPos;
uniform vec3 u_camPos;
uniform vec4 u_waveScale;

varying vec3 normal;
varying vec3 toEyeW;
varying vec4 v_tex;

#ifndef NEW_FOG
uniform vec4 fogParam[3];

varying vec4 oFogColor;

float ComputeFog(vec3 camToWorldPos, vec3 param)
{
	float fdist = max(length(camToWorldPos) - param.x, 0.0);
	float density = clamp(clamp(fdist/(param.y-param.x), 0.0, 1.0) * param.z, 0.0, 1.0);
	return 1.0 - density;
}
#endif

float GetWave(vec3 vPos)
{
	vec4 u_oceanParam = vec4(1.2, 1.2, 0.2, 1.0);
	float fAnimAmplitudeScale = 0.2 / 5.0;
	float fPhaseTest = length(vPos.xz);
	vec4 vPhases = u_oceanParam.x * vec4(0.1, 0.159, 0.557, 0.2199);
	vec4 vAmplitudes = u_oceanParam.y * vec4(1, 0.5, 0.25, 0.5);
	vec4 vCosPhase = (fPhaseTest + vPos.x)* vPhases;                                    // 1 inst
	vec4 vCosWave = 2.0 * cos(vCosPhase);                               // 8 inst
	vec4 vSinPhase = (fPhaseTest + vPos.z)* vPhases;                                    // 1 inst
	vec4 vSinWave = 2.0 * sin(vSinPhase);                               // 8 inst
	float fAnimSum = dot(vCosWave, vAmplitudes) + dot(vSinWave, vAmplitudes);                 // 3 inst
	return fAnimSum * fAnimAmplitudeScale;                                                 // 1 inst
}

void main()
{
	float u_gridSize = 0.5;
	vec4 u_oceanParam = vec4(1.2, 1.2, 0.2, 1.0);
	vec4 u_WaveParam = vec4(0.125, 0.25, 1.0, 0.1);

	vec3 blockPos = inPosition.xyz / 2048.0 + sectionPos.xyz;
	gl_Position = matWVP * vec4(blockPos, 1.0);

	vec3 WaveOffsetInWorldSpace = vec3(u_waveScale.x, 0, u_waveScale.y);

	vec3 NPos = blockPos + vec3(u_gridSize, 0.0, 0.0);
	NPos.y += GetWave(NPos*u_oceanParam.z + WaveOffsetInWorldSpace);
	NPos -= blockPos;

	vec3 TPos = blockPos + vec3(0.0, 0.0, -u_gridSize);
	TPos.y += GetWave(TPos*u_oceanParam.z + WaveOffsetInWorldSpace);
	TPos -= blockPos;

	mat3 TBN;
	TBN[0] = normalize(NPos);						// Tangent goes along object space x-axis.
	TBN[1] = normalize(TPos);						// Binormal goes along object space -z-axis
	TBN[2] = normalize(cross(TBN[0], TBN[1]));		// Normal goes along object space y-axis
	normal = (TBN[2]);

	toEyeW = normalize(u_camPos.xyz - blockPos);

	v_tex.xy = blockPos.xz * 0.00625;
	v_tex.zw = blockPos.xz * 0.025;

#ifndef NEW_FOG
	oFogColor = vec4(fogParam[1].rgb, ComputeFog(blockPos-fogParam[2].xyz, fogParam[0].xyz));
#endif
	
}
