#version 300 es

in highp vec4 inPosition;
in vec2 inTexCoord;
in vec4 inColor1;
in vec4 inColor;
in vec2 inTexIndex;

uniform mat4 matWVP;
uniform vec4 sectionPos;

out vec2 texCoord_texture;
out vec4 color;
out float oTexIndex;
void main(void)
{
	vec3 blockPos = inPosition.xyz / 2048.0;	
	blockPos = sectionPos.xyz + blockPos;
	gl_Position = matWVP * vec4(blockPos, 1.0);

	texCoord_texture = inTexCoord / 2048.0;
	texCoord_texture.x +=  inColor1.x * 0.000001 + inColor.x * 0.000001;
	
	oTexIndex = inTexIndex.x;
}

