#version 300 es

precision mediump float;

out float FragColor;

in vec2 texCoord;

uniform sampler2D gDepthTexture;
uniform sampler2D gNormal;

// parameters (you'd probably want to use them as uniforms to more easily tweak the effect)
const int kernelSize = 64;
const int noiseSize = 16;
const float radius = 0.5;
const float bias = 0.025;

uniform vec3 ssaoKernel[kernelSize];
uniform vec3 noiseDirection[noiseSize];
uniform mat4 projection;
uniform mat4 view;
uniform mat4 inverseProjectionMatrix;
uniform vec2 screenSize;

vec3 calcViewPos(vec2 coords)
{
    float depth = texture(gDepthTexture, coords).x;
    vec4 pos;
    pos.w = 1.0;
    pos.z = depth * 2.0 - 1.0;
    pos.x = coords.x * 2.0 - 1.0;
    pos.y = coords.y * 2.0 - 1.0;
 
    vec4 viewPos = inverseProjectionMatrix * pos;
    return viewPos.xyz / viewPos .w;
}

vec3 calcNoiseDir(vec2 coords)
{
    // noiseSize = 16
    int x = int(mod(coords.x * screenSize.x, 4.0));
    int y = int(mod(coords.y * screenSize.y, 4.0));
    return noiseDirection[x * 4 + y];
}

void main()
{
    // get input for SSAO algorithm
    vec3 viewPos = calcViewPos(texCoord);
    //vec3 viewPos = texture(gPosition, texCoord).xyz;
    vec3 normal = texture(gNormal, texCoord).rgb;
    normal = (view * vec4(normal, 1.0)).rgb;
    normal = normalize(normal);
    //vec3 randomVec = normalize(texture(texNoise, texCoord * noiseScale).xyz);
    vec3 randomVec = normalize(calcNoiseDir(texCoord));

    // create TBN change-of-basis matrix: from tangent-space to view-space
    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 TBN = mat3(tangent, bitangent, normal);

    // iterate over the sample kernel and calculate occlusion factor
    float occlusion = 0.0;
    for(int i = 0; i < kernelSize; ++i)
    {
        // get sample position
        vec3 samplePos = TBN * ssaoKernel[i]; // from tangent to view-space
        samplePos = viewPos + samplePos * radius; 
        
        // project sample position (to sample texture) (to get position on screen/texture)
        vec4 offset = vec4(samplePos, 1.0);
        offset = projection * offset; // from view to clip-space
        offset.xyz /= offset.w; // perspective divide
        offset.xyz = offset.xyz * 0.5 + 0.5; // transform to range 0.0 - 1.0
        
        // get sample depth
        float sampleDepth = calcViewPos(offset.xy).z; // get depth value of kernel sample
        //float sampleDepth = texture(gPosition, offset.xy).z;
        
        // range check & accumulate
        float rangeCheck = smoothstep(0.0, 1.0, radius / abs(viewPos.z - sampleDepth));
        occlusion += (sampleDepth >= samplePos.z + bias ? 1.0 : 0.0) * rangeCheck;  
    }

    occlusion = 1.0 - (occlusion / float(kernelSize));
    
    FragColor = occlusion;
}
