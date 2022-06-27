#version 100

#ifdef GL_FRAGMENT_PRECISION_HIGH
	precision highp float;
#else
	precision mediump float;
#endif

attribute highp vec4 inPosition;

uniform mat4 u_mvp;
uniform float u_gridSize;
uniform vec4 u_oceanParam;
uniform vec4 u_waveScale;
uniform vec2 u_waveMovement;
uniform vec4 u_WaveParam;
uniform vec3 u_ShoreColor;
uniform vec3 u_SeaColor;
uniform vec3 u_camPos;
uniform vec4 u_fogParam[2];
uniform vec3 u_fogPos;

varying vec3 normal;
varying vec4 v_fogColor;
varying vec4 v_tex;
varying vec3 toEyeW;
varying vec4 v_seaColor;
varying float v_depthfactor;

float ComputeVolumetricFog(vec3 cameraToWorldPos, float WorldPosHeight, float cFogDistStart, float cFogRcpDist, float cFogHeight, float cFogGlobalDensity, float cFogHeightFalloff)
{
	vec3 g_FogDirection = vec3(0.0, -1.0, 0.0);
	float dist = length(cameraToWorldPos);
	
	float fDist = max(dist - cFogDistStart, 0.0);
	float fogInt = (1.0 - exp(-fDist / cFogRcpDist));
	if (WorldPosHeight > cFogHeight)
	{
		float fexp = cFogHeight - WorldPosHeight;
		float t = -cFogHeightFalloff * fexp;
		fogInt *= (1.0 - exp(-t)) / t;
	}
	return clamp(exp(-cFogGlobalDensity * fogInt),0.0,1.0);
}

float GetWave(vec3 vPos)
{
	// constant to scale down values a bit
	float fAnimAmplitudeScale = 1.0 / 5.0;
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
	vec3 posL = inPosition.xyz;
	// calculate project space
	vec3 WaveOffsetInWorldSpace = vec3(u_waveScale.x, 0, u_waveScale.y);
	vec3 worldPos = posL;
	float waveheight = GetWave(worldPos*u_oceanParam.z + WaveOffsetInWorldSpace);
	worldPos.y += waveheight;
	gl_Position = u_mvp * vec4(worldPos, 1.0);
	float depth = 1.0 - min((10.0) / (10.0*u_WaveParam.z), 1.0);
	v_depthfactor = depth;
	
	// calculate tangent and binormal
	vec3 NPos = posL + vec3(u_gridSize, 0.0, 0.0);
	NPos.y += GetWave(NPos*u_oceanParam.z + WaveOffsetInWorldSpace);
	NPos -= worldPos;
	
	vec3 TPos = posL + vec3(0.0, 0.0, -u_gridSize);
	TPos.y += GetWave(TPos*u_oceanParam.z + WaveOffsetInWorldSpace);
	TPos -= worldPos;
	
	// Build TBN-basis.  For flat water grid in the xz-plane in 
	// object space, the TBN-basis has a very simple form.
	mat3 TBN;
	TBN[0] = normalize(NPos);						// Tangent goes along object space x-axis.
	TBN[1] = normalize(TPos);						// Binormal goes along object space -z-axis
	TBN[2] = normalize(cross(TBN[0], TBN[1]));	// Normal goes along object space y-axis
	normal = (TBN[2]);
	
	toEyeW = u_camPos.xyz - worldPos;
	
	// Water alpha
	float maxValue = 0.5;//0.5;
	float depthalpha = 1.0 - (depth - maxValue) * (1.0 / maxValue);
	depthalpha = depthalpha * depthalpha;
	depthalpha = depthalpha * 0.8;
	depthalpha = min(1.0, depthalpha);
	
	// UV coordinates
	vec2 texcoord = inPosition.xz * u_WaveParam.xy;
	v_tex.xy = texcoord * u_waveScale.z + u_waveMovement;;
	v_tex.zw = texcoord * u_waveScale.w + u_waveMovement;;
	
	// Calculate colors
	float blendFactor = 1.0 - min(1.0, depth * 1.6);
	float tx = texcoord.x - 0.5;
	float ty = texcoord.y - 0.5;
	float tmp = (tx * tx + ty * ty) / (0.75 * 0.75);
	float blendFactorMul = step(1.0, tmp);
	// Can't be above 1.0, so no clamp needed
	float blendFactor2 = clamp(blendFactor, 0.0, 1.0);
	blendFactor = mix(blendFactor2, blendFactor, blendFactorMul);
	v_seaColor = vec4(mix(u_ShoreColor, u_SeaColor, blendFactor), depthalpha);
	
	float density = ComputeVolumetricFog(worldPos.xyz - u_fogPos, worldPos.y, u_fogParam[0].x, u_fogParam[0].y, u_fogParam[0].z, u_fogParam[0].w, u_fogParam[1].x);
	v_fogColor = vec4(u_fogParam[1].yzw, density);
}
