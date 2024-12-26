#include <metal_stdlib>
using namespace metal;
#include "RasterizerData.h"
#include "ShaderTypes.h"

#pragma mark Pixelation Shader
[[fragment]]
float4 fragmentPixelationShader(RasterizerData in [[stage_in]], texture2d<half> colorTexture [[texture(TI_PixelationInputImage)]],
                                constant int *size [[buffer(FIP_Radius)]], constant float *width [[buffer(FIP_Width)]],
                                constant float *heigth [[buffer(FIP_Height)]], constant float *texelSizeX [[buffer(FIP_TexelSizeX)]],
                                constant float *texelSizeY [[buffer(FIP_TexelSizeY)]]) {
    /// Texture sampler
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

    half4 colorSample = 0.0;
    /// If size of square is 0 return pixel's initial value
    if (*size == 0)
        return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));

    int startX = static_cast<int>(static_cast<float>(*width) * in.textureCoordinate.x);
    int startY = static_cast<int>(static_cast<float>(*heigth) * in.textureCoordinate.y);

    startX -= startX % *size;
    startY -= startY % *size;

    float x = static_cast<float>(startX) / static_cast<float>(*width);
    float y = static_cast<float>(startY) / static_cast<float>(*heigth);

    /// Accumulating pixel colors in certain square
    for (int i = 0; i < *size; i++) {
        for (int j = 0; j < *size; j++) {
            colorSample += colorTexture.sample(textureSampler, float2(x + i * *texelSizeX, y + j * *texelSizeY));
        }
    }

    /// Returning averaged value of color
    return static_cast<float4>(colorSample / pow(*size, 2.0));
}
