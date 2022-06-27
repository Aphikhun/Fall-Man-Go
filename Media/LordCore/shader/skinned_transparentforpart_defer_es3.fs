﻿#version 300 es

precision mediump float;

#include "headers/defer_basic.glsl"

uniform sampler2D texSampler;

uniform float discardAlpha;
uniform int useOriginalcolor;
uniform vec4 naturalColor;
uniform vec4 customColor;
uniform int isUiActor;
uniform int useEdge;
uniform vec4 edgeColor;

////////////////////////////////////////////////////
//part的参数
uniform mediump vec3 uvParam;
uniform mediump float alpha;
uniform mediump float subMeshAlpha;
uniform mediump vec4 subMeshColor;
uniform mediump vec3 subMeshUVParam;
uniform mediump vec3 subMeshOffsetParam;
uniform mediump float isSubMesh;
uniform mediump float customThreshold;
uniform mediump vec4 multiCalColor;
////////////////////////////////////////////////////

float m_useOverlayColorReplaceMode;
int m_useReflect;
int m_useReflectMaskTexture;
float m_reflectMask;
int m_useOriginalcolor;
int m_useEdge;

in vec2 lightMapUV;

void main(void)
{
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	mediump float fSubMesh = step(0.0, isSubMesh);
	mediump vec2 coord = (1.0 - fSubMesh) * (texCoord * uvParam.xy) + fSubMesh * ((texCoord + subMeshOffsetParam.xy) * subMeshUVParam.xy);
	mediump vec4 color = vec4(multiCalColor.rgb, 1.0);
	mediump float useOverlayColorReplaceMode = multiCalColor.a;

	mediump vec4 textureColor = texture(texSampler, coord);
	mediump float textureAlpha = textureColor.a;

	if (textureColor.a < discardAlpha)
	{
		discard;
	}

	mediump float fAlpha = step(textureColor.a, 0.3);
	textureColor.rgb = (1.0 - fAlpha) * textureColor.rgb + fAlpha * (textureColor.rgb * (1.0 - customColor.a) + customColor.rgb * customColor.a);
	textureColor.a = (1.0 - fAlpha) * textureColor.a + fAlpha;

	mediump vec4 finalColor = (1.0 - useOverlayColorReplaceMode) * textureColor * color + useOverlayColorReplaceMode * color;
	mediump float fNature = dot(max(sign(vec3(1.0) - naturalColor.rgb), 0.0), vec3(1.0));
	fNature = sign(fNature);
	textureColor.a = (1.0 - fNature) * textureColor.a + fNature * (finalColor.r * 0.299 + finalColor.g * 0.587 + finalColor.b * 0.114);
	finalColor = (1.0 - fNature) * finalColor + fNature * naturalColor * textureColor.a;

	finalColor.a *= (1.0 - fSubMesh) * alpha + fSubMesh * subMeshAlpha;

	mediump vec4 c0 = vec4(textureColor.rgb * customColor.rgb, finalColor.a);
	mediump vec4 c1 = vec4(textureColor.rgb, finalColor.a);
	mediump vec4 c2 = vec4(textureColor.rgb * subMeshColor.rgb, finalColor.a);
	mediump float fCustom = step(textureAlpha, customThreshold);
	finalColor = fCustom * c0 + (1.0 - fCustom) * c1;
	finalColor = (1.0 - fSubMesh) * finalColor + fSubMesh * c2;
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////

	DrawToGBuffers(finalColor);
	//DrawToGBuffers(vec4(1.0, 1.0, 1.0, 0.0));
}
