#include <metal_stdlib>
using namespace metal;

#include "ShaderTypes.h"
#include "RasterizerData.h"


#pragma mark Gaussian Blur Shader
fragment float4 fragmentGaussianBlurShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_GaussianBlurInputImage) ]],
                                           constant int* radius [[buffer(FIGB_BlurRadius)]],
                                           constant float* texelSizeX [[buffer(FIGB_TexelSizeX)]],
                                           constant float* texelSizeY [[buffer(FIGB_TexelSizeY)]],
                                           constant float* matrix [[ buffer(FIGB_Matrix) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear,
                                      r_address::clamp_to_edge,
                                      s_address::clamp_to_edge,
                                      t_address::clamp_to_edge);
    
    
    if(*radius == 0)
        return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));
    
    float4 colorSample = 0.0;
    float x = *texelSizeX, y = *texelSizeY, r = static_cast<float>(*radius);

    for(unsigned int i{0}; i < 2*r+1; i++)
    {
        for(unsigned int j{0}; j < 2*r+1; j++)
        {
            float2 offset = float2((i - r) * x, (j - r) * y);
            colorSample += static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate + offset)) * matrix[static_cast<int>(2*r+1)*i + j];
        }
    }
    
    
    return colorSample;
}





#pragma mark Kawase Blur Shader
fragment float4 fragmentKawaseBlurShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_KawaseBlurInputImage) ]],
                                           constant int* radius [[buffer(FIKB_BlurRadius)]],
                                           constant float* texelSizeX [[buffer(FIKB_TexelSizeX)]],
                                           constant float* texelSizeY [[buffer(FIKB_TexelSizeY)]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear,
                                      r_address::clamp_to_edge,
                                      s_address::clamp_to_edge,
                                      t_address::clamp_to_edge);
    
    if(*radius == 0)
        return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));
    
    half4 colorSample = 0.0;
    float x = *texelSizeX, y = *texelSizeY, r = static_cast<float>(*radius);
    
    colorSample += (colorTexture.sample(textureSampler, in.textureCoordinate) +
                    colorTexture.sample(textureSampler, in.textureCoordinate + float2(-r * x + 0.5 * x, -r * y + 0.5 * y)) +
                    colorTexture.sample(textureSampler, in.textureCoordinate + float2(r * x - 0.5 * x, -r * y + 0.5 * y)) +
                    colorTexture.sample(textureSampler, in.textureCoordinate + float2(-r * x + 0.5 * x, r * y - 0.5 * y)) +
                    colorTexture.sample(textureSampler, in.textureCoordinate + float2(r * x - 0.5 * x, r * y - 0.5 * y))) / 5.0;
    
    
    
    return static_cast<float4>(colorSample);
}


#pragma mark Box Blur Shader
fragment float4 fragmentBoxBlurShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_BoxBlurInputImage) ]],
                                           constant int* radius [[buffer(FIBB_BlurRadius)]],
                                           constant float* texelSizeX [[buffer(FIBB_TexelSizeX)]],
                                           constant float* texelSizeY [[buffer(FIBB_TexelSizeY)]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear,
                                      r_address::clamp_to_edge,
                                      s_address::clamp_to_edge,
                                      t_address::clamp_to_edge);
    
    if(*radius == 0)
        return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));
    
    float4 colorSample = 0.0;
    float x = *texelSizeX, y = *texelSizeY, r = static_cast<float>(*radius);
    
    for(unsigned int i{0}; i < 2*r + 1; i++)
    {
        for(unsigned int j{0}; j < 2*r + 1; j++)
        {
            colorSample += static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate + float2(-r*x + i*x, -r*y + r*y)));
        }
    }

    
    return static_cast<float4>(colorSample) / pow(2*r + 1, 2);
}


#pragma mark Circle Blur Shader
fragment float4 fragmentCircleShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_CircleBlurInputImage) ]],
                                           constant float* radius [[buffer(FICB_BlurRadius)]],
                                           constant float* locationX [[buffer(FICB_LocationX)]],
                                           constant float* locationY [[buffer(FICB_LocationY)]],
                                           constant float* texelSizeX [[buffer(FICB_TexelSizeX)]],
                                           constant float* texelSizeY [[buffer(FICB_TexelSizeY)]],
                                           constant float2* resolution [[buffer(FICB_Resolution)]],
                                           constant int* amount [[buffer(FICB_Amount)]],
                                           constant float* mixFactor [[buffer(FICB_Mix)]],
                                           constant float* matrix [[ buffer(FICB_Matrix) ]],
                                           constant bool* interpolate [[ buffer(FICB_Smooth) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear,
                                      r_address::clamp_to_edge,
                                      s_address::clamp_to_edge,
                                      t_address::clamp_to_edge);
    
    float2 centerNew = float2(*locationX, *locationY) - 0.5;
    float2 coords = in.textureCoordinate - 0.5;
    
    coords.x *= (*resolution).x / (*resolution).y;
    centerNew.x *= (*resolution).x / (*resolution).y;

    if(*radius == 0 || *amount == 0 || distance(centerNew, coords) > *radius)
       return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));
        
    float2 center = float2(*locationX, *locationY);
    half4 colorSample = 0.0;
    float x = *texelSizeX, y = *texelSizeY, r = static_cast<float>(*amount);

    for(unsigned int i{0}; i < 2*r+1; i++)
    {
        for(unsigned int j{0}; j < 2*r+1; j++)
        {
            float2 offset = float2((i - r) * x, (j - r) * y);
            colorSample.rgb += colorTexture.sample(textureSampler, in.textureCoordinate + offset).rgb * matrix[static_cast<int>(2*r+1)*i + j];
        }
    }
    
    float factor = *mixFactor;
    if(*interpolate) factor *= 1.0 - pow(distance(center, in.textureCoordinate) / *radius, 3.0);
    
    return static_cast<float4>(mix(colorTexture.sample(textureSampler, in.textureCoordinate), colorSample, factor));
}
