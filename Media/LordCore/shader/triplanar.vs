#version 100

attribute highp vec3 inPosition;
attribute vec3 inNormal;

uniform mat4        matWorld;
uniform mat4        matWVP;

uniform vec3        lightDir;
uniform vec3        viewPos;
uniform vec4        lightColor;

uniform vec3 		A_uv_offset;
uniform int 		A_uv_tiles;  //  : hint_range(1, 16) = 1
uniform float 		A_tri_blend_sharpness;  //  : hint_range(0.001, 50.0) = 17.86

uniform vec3 		B_uv_offset;
uniform int 		B_uv_tiles;  //  : hint_range(1, 16) = 1
uniform float 		B_tri_blend_sharpness;  //  : hint_range(0.001, 50.0) = 17.86

varying vec3 		A_uv_triplanar_pos;
varying vec3 		A_uv_power_normal;
varying vec3 		B_uv_triplanar_pos;
varying vec3 		B_uv_power_normal;
varying vec3 		vertex_normal;
varying vec3        vertex_model_pos;
varying vec4        light_intensity;

void main() 
{
	vertex_normal = inNormal;
    vertex_model_pos = inPosition;

    A_uv_power_normal=pow(abs(inNormal),vec3(A_tri_blend_sharpness));
    A_uv_power_normal/=dot(A_uv_power_normal,vec3(1.0));
    A_uv_triplanar_pos = inPosition * float(A_uv_tiles) / (16.) + A_uv_offset;			//On VoxelTerrain 16 is 100% size, so uv_tile is multiples of 16. 
	A_uv_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
    B_uv_power_normal=pow(abs(inNormal),vec3(B_tri_blend_sharpness));
    B_uv_power_normal/=dot(B_uv_power_normal,vec3(1.0));
    B_uv_triplanar_pos = inPosition * float(B_uv_tiles) / (16.)  + B_uv_offset;
	B_uv_triplanar_pos *= vec3(1.0,-1.0, 1.0);

    // Ambient
    float LaKa = 0.3;
    // Diffuse
    float LdKd = 0.7;
    vec4 s = normalize(vec4(lightDir, 0.0));
    vec4 n = normalize(matWorld * vec4(inNormal, 0.0));

    float strength = LaKa + LdKd * max(dot(s, n), 0.0);
    light_intensity = strength * lightColor;

    gl_Position = matWVP * vec4(inPosition, 1.0);
}