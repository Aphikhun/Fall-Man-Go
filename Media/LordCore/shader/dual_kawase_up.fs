#version 100

precision mediump float;

uniform sampler2D texSampler;
uniform vec2 resolution;
uniform vec2 offset;
uniform vec2 halfPixel;

void main()
{
    vec2 uv = vec2(gl_FragCoord.xy / resolution);

    vec4 sum = texture2D(texSampler, uv + vec2(-halfPixel.x * 2.0, 0.0) * offset);
    sum += texture2D(texSampler, uv + vec2(-halfPixel.x, halfPixel.y) * offset) * 2.0;
    sum += texture2D(texSampler, uv + vec2(0.0, halfPixel.y * 2.0) * offset);
    sum += texture2D(texSampler, uv + vec2(halfPixel.x, halfPixel.y) * offset) * 2.0;
    sum += texture2D(texSampler, uv + vec2(halfPixel.x * 2.0, 0.0) * offset);
    sum += texture2D(texSampler, uv + vec2(halfPixel.x, -halfPixel.y) * offset) * 2.0;
    sum += texture2D(texSampler, uv + vec2(0.0, -halfPixel.y * 2.0) * offset);
    sum += texture2D(texSampler, uv + vec2(-halfPixel.x, -halfPixel.y) * offset) * 2.0;

    gl_FragColor = sum / 12.0;
}
