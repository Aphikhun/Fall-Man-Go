#version 300 es

[VS]
#pragma once

[PS]
#pragma once

uniform int hdr;
uniform int reinhard;
uniform float exposure;
uniform float gamma;
uniform int reciprocal;

vec3 toneMapping(vec3 hdrColor)
{
    vec3 result;
    if (hdr > 0)
    {
        if (reinhard > 0)
            result = hdrColor / (hdrColor + vec3(1.0)); // reinhard
        else
            result = vec3(1.0) - exp(-hdrColor * exposure); // exposure
    }
    else
    {
        result = hdrColor;
    }

    // gamma correct
    /*
    const float GAMMA = 2.2;
    if (gamma > 0)
    {     
        if (reciprocal > 0)
            result = pow(result, vec3(1.0 / GAMMA));
        else
            result = pow(result, vec3(GAMMA));
    }
    */
    result = pow(result, vec3(gamma));

    return result;
}
