#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;
attribute vec4 inBlendWeights;
attribute vec4 inBrightness;

uniform mat4        matWorld;
uniform mat4        matWVP;
uniform mat4        lightSpaceMatrix;

uniform vec3 		A_uv_offset;
uniform float 		A_uv_tiles;  //  : hint_range(1, 16) = 1
uniform float 		A_tri_blend_sharpness;  //  : hint_range(0.001, 50.0) = 17.86

uniform vec3 		B_uv_offset;
uniform float 		B_uv_tiles;  //  : hint_range(1, 16) = 1
uniform float 		B_tri_blend_sharpness;  //  : hint_range(0.001, 50.0) = 17.86

uniform vec3        lightDir;
uniform vec3        viewPos;
uniform vec4        lightColor;

varying vec3 		A_uv_triplanar_pos;
varying vec3 		A_uv_power_normal;
varying vec3 		B_uv_triplanar_pos;
varying vec3 		B_uv_power_normal;
varying vec3 		vertex_normal;
varying vec4        blend_weights;
varying vec4        blend_weights2;
varying vec3        lightFactor;

void main() 
{
	vertex_normal = inNormal;
    vec3 fragNormal = mat3(matWorld) * inNormal;
    blend_weights = inBlendWeights;
    blend_weights2 = inBrightness;

    float times = 2.0; // Only set to integer. If not, texture will break
    A_uv_power_normal = pow(abs(inNormal), vec3(A_tri_blend_sharpness));
    A_uv_power_normal /= dot(A_uv_power_normal, vec3(1.0));
    A_uv_triplanar_pos = inPosition * A_uv_tiles / times + A_uv_offset;

    B_uv_power_normal = pow(abs(inNormal), vec3(B_tri_blend_sharpness));
    B_uv_power_normal /= dot(B_uv_power_normal, vec3(1.0));
    B_uv_triplanar_pos = inPosition * B_uv_tiles / times + B_uv_offset;

    // Ambient
    mediump float ambientStrength = 0.3;
    mediump vec3 ambient = ambientStrength * lightColor.rgb;
    // Diffuse
    mediump vec3 s = normalize(lightDir);
    mediump vec3 n = normalize(fragNormal);
    mediump float diff = max(dot(s, n), 0.0);
    mediump vec3 diffuse = 0.7 * diff * lightColor.rgb;

    lightFactor = ambient + diffuse;

    gl_Position = matWVP * vec4(inPosition, 1.0);
}
