[VS]

[PS]
#pragma once

uniform sampler2D vEmissiveSampler;
uniform vec3 vEmissiveColor;
uniform vec2 vEmissiveInfos;

vec3 computeEmissiveColor(sampler2D emissiveSampler, vec2 uv)
{
    vec3 emissiveColor = vEmissiveColor;
    emissiveColor += texture(emissiveSampler, uv).rgb * vEmissiveInfos.y;
    return emissiveColor;
}