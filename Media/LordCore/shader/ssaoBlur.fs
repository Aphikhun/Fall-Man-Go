#version 300 es

precision mediump float;

out float FragColor;

in vec2 texCoord;

uniform sampler2D ssaoInput;
uniform vec2 screenSize;

void main() 
{
    vec2 texelSize = 1.0 / vec2(screenSize);
    float result = 0.0;
    for (int x = -2; x < 2; ++x) 
    {
        for (int y = -2; y < 2; ++y) 
        {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture(ssaoInput, texCoord + offset).r;
        }
    }

    FragColor = result / (4.0 * 4.0);
}  
