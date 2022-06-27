#version 300 es

precision mediump float;

layout(location = 0) in highp vec3 inPosition;
layout(location = 1) in vec2 inTexCoord;

invariant gl_Position;
out vec2 texCoord;

void main()
{
    texCoord = inTexCoord;
    gl_Position = vec4(inPosition, 1.0);
}
