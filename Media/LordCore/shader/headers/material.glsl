#version 300 es

[VS]
#pragma once

[PS]
#pragma once

struct Material {
    //sampler2D diffuse;
    //sampler2D specular;
    //float shininess;
    float roughness;                                            //代替shininess
    float metalness;                                            //new
    float useBloom;                                             // bloom 辉光
};

uniform Material material;
