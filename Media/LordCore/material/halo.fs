#version 100

precision mediump float;

varying mediump vec4 color;
varying mediump vec2 texCoord;

void main(void)
{
    float alpha = 1.0 - abs(texCoord.y - 0.5) * 2.0;

	gl_FragColor = vec4(color.rgb, alpha);
}