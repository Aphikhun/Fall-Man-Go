#version 300 es

precision mediump float;

uniform sampler2D texSampler;
uniform sampler2D bloomFlagTexture;
uniform vec3 bloomParam;

in vec2 texCoord;

out vec4 FragColor;

void main(void)
{
	float bloomThreshold = bloomParam.x;
	vec4 textureColor = texture(texSampler, texCoord);

	float bloomFlag = texture(bloomFlagTexture, texCoord).a;
	bloomFlag = 1.0 - bloomFlag;

	vec4 output_shader;
	output_shader.rgb = clamp(textureColor.rgb - bloomFlag - bloomThreshold, 0.0, 1.0) / (1.0 - bloomThreshold); 
	output_shader.a = 1.0;
	FragColor = output_shader;
}