#version 100

attribute vec4 inPosition;
attribute vec4 inTangent;
attribute vec4 inNormal;
attribute vec4 inColor;

uniform mat4 matWVP;
uniform vec2 screenSize;
uniform vec4 nearPlaneInfo;

varying vec4 color;
varying vec2 texCoord;

void main(void)
{
    vec3 position = inPosition.xyz;
    vec3 nextPosition = inTangent.xyz;
    vec3 lastPosition = inNormal.xyz;
    float width = inNormal.w;
    vec3 nearPlaneNormal = nearPlaneInfo.xyz;
    float nearPlaneDistance = nearPlaneInfo.w;

	color = inColor;
	texCoord = vec2(inPosition.w, inTangent.w);

    // calculate vertex offset under screen space to get real vertex position
    vec4 refPoint0 = matWVP * vec4(lastPosition, 1.0);
    vec4 refPoint1 = matWVP * vec4(nextPosition, 1.0);
    vec4 cornerPoint = matWVP * vec4(position, 1.0);

    vec3 cornerPointInNDC = cornerPoint.xyz / cornerPoint.w;
    vec3 refPoint1InNDC = refPoint1.xyz / refPoint1.w;
    vec2 refPoint0InScreenSpace = refPoint0.xy / refPoint0.w * screenSize;
    vec2 refPoint1InScreenSpace = refPoint1InNDC.xy * screenSize;
    vec2 cornerPointInScreenSpace = cornerPointInNDC.xy * screenSize;
    vec2 dir0InScreenSpace = normalize((refPoint0InScreenSpace - cornerPointInScreenSpace) * refPoint0.w * cornerPoint.w);
    vec2 dir1InScreenSpace = normalize((refPoint1InScreenSpace - cornerPointInScreenSpace) * refPoint1.w * cornerPoint.w);
    vec2 tangentInScreenSpace = dir0InScreenSpace - dir1InScreenSpace;
    float ratio = dot(tangentInScreenSpace, dir0InScreenSpace);
    vec2 offsetInScreenSpace = vec2(-tangentInScreenSpace.y, tangentInScreenSpace.x) * (width / ratio);
    vec2 offsetInNDC = offsetInScreenSpace / screenSize;

    // if the point is in front of camera near plane, set position to the projection to the plane
    float distanceToPlane = nearPlaneDistance - dot(nearPlaneNormal, position);
    if (distanceToPlane > 0.0)
    {
        vec3 direction = nextPosition - position;
        float dotResult = dot(nearPlaneNormal, direction);
        if (dotResult == 0.0)
        {
            // whole quad will be clipped
            gl_Position = vec4(-1);
            return;
        }
        float offsetToProjection = distanceToPlane / dotResult;
        position += offsetToProjection * direction;
        cornerPoint = matWVP * vec4(position, 1.0);
        cornerPointInNDC = cornerPoint.xyz / cornerPoint.w;
    }
    
    vec4 outPos = vec4(cornerPointInNDC, 1.0);
    outPos.xy += offsetInNDC;
    gl_Position = outPos;
}