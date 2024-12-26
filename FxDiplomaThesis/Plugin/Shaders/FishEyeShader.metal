#include <metal_stdlib>
using namespace metal;
#include "RasterizerData.h"
#include "ShaderTypes.h"

#pragma mark Fish eye Shader
[[fragment]]
float4 fragmentFishEyeShader(RasterizerData in [[stage_in]], texture2d<half> colorTexture [[texture(TI_FishEyeInputImage)]],
                             constant float *locationX [[buffer(FIFE_LocationX)]], constant float *locationY [[buffer(FIFE_LocationY)]],
                             constant float *radius [[buffer(FIFE_Radius)]], constant float *amount [[buffer(FIFE_Amount)]]) {
    /// Texture sampler
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear, s_address::clamp_to_zero, t_address::clamp_to_zero);

    float2 center = float2(*locationX, *locationY);

    float dist = distance(center, in.textureCoordinate);
    /// Calculating new distance of pixel
    float newR = dist * (1.0 + *amount * pow(dist, 2.0));

    /// Calculating the coords of pixel from which color will be sampled
    float2 coords = 0.0;
    coords.x = *locationX + (in.textureCoordinate.x - *locationX) * newR / dist * *radius;
    coords.y = *locationY + (in.textureCoordinate.y - *locationY) * newR / dist * *radius;

    return static_cast<float4>(colorTexture.sample(textureSampler, coords));
}
