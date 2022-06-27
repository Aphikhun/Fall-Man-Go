[VS]

[PS]
// uniform vec4 vSpecularColor;
uniform sampler2D specularSampler;

vec4 computeSpecularColor(sampler2D specular, vec2 uv)
{
    return texture(specular, uv);
}