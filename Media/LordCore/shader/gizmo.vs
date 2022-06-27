#version 100
attribute highp vec3 inPosition;
attribute vec3 inNormal;

uniform mat4 matWorld;
uniform mat4 matView;
uniform mat4 matProj;
uniform float scale;


varying vec3 normal;
varying vec3 fragPos;

void main(void)
{
	fragPos = vec3(matWorld * vec4(scale * inPosition, 1.0));
	normal = vec3(matWorld * vec4(inNormal, 0.0));
	gl_Position = matProj * matView * matWorld * vec4(scale * inPosition, 1.0);
}