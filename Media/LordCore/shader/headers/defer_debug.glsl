#version 300 es

[VS]

[PS]
#pragma once

vec3 DebugTo4Quad(vec3 color, vec3 LB, vec3 LT, vec3 RB)
{
	bool debugging = false;
	if (debugging)
    {
        if (texCoord.x < 0.5)
        {
            if (texCoord.y < 0.5)
                return (LB - 110.0) / 120.0;
            else
                return LT;
        }
        else
        {
            if (texCoord.y < 0.5)
                return RB;
            else
                return color;
        }
    }
	return color;
}
