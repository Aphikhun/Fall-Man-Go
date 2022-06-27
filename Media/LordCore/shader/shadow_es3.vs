#version 300 es

precision mediump float;


////////////////////////////////////////////////////
//part的参数
layout(location = 0) in highp vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec3 inTexCoord;
layout(location = 3) in vec3 inTexCoord1;
layout(location = 4) in vec3 inTexCoord2;

uniform highp mat4 matWVP;

invariant gl_Position;
////////////////////////////////////////////////////

void main(void)
{
	gl_Position = matWVP * vec4(inPosition, 1.0);
}
