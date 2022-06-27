[VS]

[PS]
#pragma once
uniform sampler2D bumpSampler;
uniform vec3 vBumpInfos;
uniform vec2 vTangentSpaceParams;


vec3 perturbNormalBase(mat3 cotangentFrame, vec3 normal, float scale)
{
    return normalize(cotangentFrame * normal);
}
vec3 perturbNormal(mat3 cotangentFrame, vec3 textureSample, float scale)
{
    return perturbNormalBase(cotangentFrame, textureSample * 2.0 - 1.0, scale);
}

mat3 cotangent_frame(vec3 normal, vec3 p, vec2 uv, vec2 tangentSpaceParams)
{
    uv = gl_FrontFacing ? uv : -uv;
    vec3 dp1 = dFdx(p);
    vec3 dp2 = dFdy(p);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);
    vec3 dp2perp = cross(dp2, normal);
    vec3 dp1perp = cross(normal, dp1);
    vec3 tangent = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 bitangent = dp2perp * duv1.y + dp1perp * duv2.y;
    tangent *= tangentSpaceParams.x;
    bitangent *= tangentSpaceParams.y;
    float invmax = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent)));
    return mat3(tangent * invmax, bitangent * invmax, normal);
}

vec3 perturbNormal(mat3 cotangentFrame, vec2 uv)
{
    return perturbNormal(cotangentFrame, texture(bumpSampler, uv).xyz, vBumpInfos.y);
    // return texture(bumpSampler).xyz;
}
vec3 perturbNormal(mat3 cotangentFrame, vec3 color)
{
    return perturbNormal(cotangentFrame, color, vBumpInfos.y);
}
mat3 cotangent_frame(vec3 normal, vec3 p, vec2 uv)
{
    return cotangent_frame(normal, p, uv, vTangentSpaceParams);
}