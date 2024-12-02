#include <metal_stdlib>
using namespace metal;
#include "ShaderTypes.h"
#include "RasterizerData.h"

#pragma mark Fish eye Shader
[[fragment]]
float4 fragmentFishEyeShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_FishEyeInputImage) ]],
                                constant float* locationX [[ buffer(FIFE_LocationX) ]],
                                constant float* locationY [[ buffer(FIFE_LocationY) ]],
                                constant float* radius [[ buffer(FIFE_Radius) ]],
                                constant float* amount [[ buffer(FIFE_Amount) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear,
                                      s_address::clamp_to_zero,
                                      t_address::clamp_to_zero);
    
    float2 center = float2(*locationX, *locationY);
    
    
//    float2 coords = in.textureCoordinate - center;
//    float dist = distance(coords, float2(0.0, 0.0));
//    
//    float rad = *radius;
//    
//    float scale = 1.0 + ((0.5 - dist / 0.5) * *amount);
//    coords *= scale * rad;
//    coords += center;
//    if(coords.x < 0.0 || coords.x > 1.0 || coords.y < 0.0 || coords.y > 1.0) return float4(float3(0.0), 0.0);
    
    
    float dist = distance(center, in.textureCoordinate);
    float newR = dist * (1.0 + *amount * pow(dist, 2.0));
    
    float2 coords = 0.0;
    coords.x = *locationX + (in.textureCoordinate.x - *locationX) * newR / dist * *radius;
    coords.y = *locationY + (in.textureCoordinate.y - *locationY) * newR / dist * *radius;

    
    
    
    return static_cast<float4>(colorTexture.sample(textureSampler, coords));

}
