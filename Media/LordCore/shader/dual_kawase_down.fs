#version 100

precision mediump float;

uniform sampler2D texSampler;
uniform vec2 resolution;
uniform vec2 offset;
uniform vec2 halfPixel;

void main()
{
    vec2 uv = vec2(gl_FragCoord.xy / resolution);

    vec4 sum = texture2D(texSampler, uv) * 4.0;
    sum += texture2D(texSampler, uv - halfPixel.xy * offset);
    sum += texture2D(texSampler, uv + halfPixel.xy * offset);
    sum += texture2D(texSampler, uv + vec2(halfPixel.x, -halfPixel.y) * offset);
    sum += texture2D(texSampler, uv - vec2(halfPixel.x, -halfPixel.y) * offset);

    gl_FragColor = sum / 8.0;
}
