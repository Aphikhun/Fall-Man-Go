#version 100

attribute highp vec3 inPosition;

uniform mat4 matWorld;
uniform mat4 matWVP;

void main(void)
{
	vec4 worldPos = matWorld * vec4(inPosition, 1.0);
	gl_Position = matWVP * worldPos;
}
