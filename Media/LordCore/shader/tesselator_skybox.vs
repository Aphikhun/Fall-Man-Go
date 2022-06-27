#version 100

attribute highp vec3 inPosition;

uniform mat4 matRotate;
uniform mat4 matWorld;
uniform mat4 matWVP;

varying vec3 TexCoords;

void main(void)
{
	TexCoords = inPosition;
	vec4 rotatePos = matRotate * vec4(inPosition, 1.0);
	vec4 worldPos = matWorld * rotatePos;
	gl_Position = matWVP * worldPos;
	gl_Position.z = gl_Position.w;
}
