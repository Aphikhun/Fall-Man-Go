#version 100

attribute highp vec3 inPosition;
uniform mat4 world;

uniform mat4 viewProjection;
uniform vec3 biasAndScaleSM;
uniform vec2 depthValuesSM;
uniform mat4 scaleMat;

varying float vDepthMetricSM;


void main(void)
{
    vec3 positionUpdated = inPosition;
    mat4 finalWorld = world;
    vec4 worldPos = finalWorld * vec4(positionUpdated, 1.0);
    gl_Position = viewProjection * worldPos ;
    // gl_Position = vec4(1.0, 0.0, 0.5, 1.0);
    vDepthMetricSM = ((gl_Position.z + depthValuesSM.x) / (depthValuesSM.y)) + biasAndScaleSM.x;
}