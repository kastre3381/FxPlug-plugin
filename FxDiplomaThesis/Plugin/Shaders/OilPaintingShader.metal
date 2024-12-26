#include <metal_stdlib>
using namespace metal;
#include "RasterizerData.h"
#include "ShaderTypes.h"

#pragma mark Oil Painting Shader
[[fragment]]
float4 fragmentOilPaintingShader(RasterizerData in [[stage_in]], texture2d<half> colorTexture [[texture(TI_OilPaintingInputImage)]],
                                 constant int *radius [[buffer(FIOP_Radius)]], constant int *levelOfIntencity [[buffer(FIOP_LevelOfIntencity)]],
                                 constant float *texelSizeX [[buffer(FIOP_TexelSizeX)]], constant float *texelSizeY [[buffer(FIOP_TexelSizeY)]]) {
    /// Texture sampler
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

    /// If radius of effect is 0 return the initial pixel's value
    if (*radius == 0)
        return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));

    float x = *texelSizeX, y = *texelSizeY;
    unsigned int r = *radius, loi = *levelOfIntencity;
    /// Creating incencity count and average color tables
    int intensityCount[256] = {0};
    float3 averageColor[256] = {float3(0.0)};

    for (unsigned int i{0}; i < 256; i++) {
        intensityCount[i] = 0;
        averageColor[i] = float3(0.0);
    }

    int add = 1;

    for (unsigned int i{0}; i < 2 * r + 1; i += add) {
        for (unsigned int j{0}; j < 2 * r + 1; j += add) {
            /// Calculating offset
            float2 offset = float2((i - float(r)) * x, (j - float(r)) * y);

            float4 color = static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate + offset));

            /// Calculating intensity of pixel
            int currIntensity = int(((color.r + color.g + color.b) / 3.0) * (float(loi)));

            /// incrementing the intensity count and average color at certain index
            intensityCount[currIntensity]++;
            averageColor[currIntensity] += color.rgb;
        }
    }

    int curMax = intensityCount[0];
    int maxIndex = 0;

    /// Searching for maximum intensity
    for (unsigned int i{1}; i < loi; i++) {
        if (intensityCount[i] > curMax) {
            curMax = intensityCount[i];
            maxIndex = i;
        }
    }

    float3 finalColor = (curMax > 0) ? averageColor[maxIndex] / float(curMax) : float3(0.0);

    return float4(finalColor, 1.0);
}
