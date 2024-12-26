#include <metal_stdlib>
using namespace metal;
#include "RasterizerData.h"
#include "ShaderTypes.h"

#pragma mark Echo Shader
[[fragment]]
float4 fragmentEchoShader(
    RasterizerData in [[stage_in]], texture2d<half> colorTexture0 [[texture(TI_TimingEchoInputImage0)]],
    texture2d<half> colorTexture1 [[texture(TI_TimingEchoInputImage1)]], texture2d<half> colorTexture2 [[texture(TI_TimingEchoInputImage2)]],
    texture2d<half> colorTexture3 [[texture(TI_TimingEchoInputImage3)]], texture2d<half> colorTexture4 [[texture(TI_TimingEchoInputImage4)]],
    texture2d<half> colorTexture5 [[texture(TI_TimingEchoInputImage5)]], texture2d<half> colorTexture6 [[texture(TI_TimingEchoInputImage6)]],
    texture2d<half> colorTexture7 [[texture(TI_TimingEchoInputImage7)]], texture2d<half> colorTexture8 [[texture(TI_TimingEchoInputImage8)]],
    constant int *texturesAmount [[buffer(FITE_TexturesAmount)]], constant int *renderingType [[buffer(FITE_TimingRenderingType)]]) {
    /// Texture sampler
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

    half4 colorSample = colorTexture0.sample(textureSampler, in.textureCoordinate);

    /// If rendering type is default or amount of textures is 0 return initial frame pixel's color
    if (*renderingType == 0 || *texturesAmount == 1)
        return static_cast<float4>(colorSample);

    /// Rendering type is backwards and forwards
    else if (*renderingType == 3) {
        if (*texturesAmount >= 2) {
            colorSample += colorTexture1.sample(textureSampler, in.textureCoordinate);
            colorSample += colorTexture2.sample(textureSampler, in.textureCoordinate);
        }
        if (*texturesAmount >= 3) {
            colorSample += colorTexture3.sample(textureSampler, in.textureCoordinate);
            colorSample += colorTexture4.sample(textureSampler, in.textureCoordinate);
        }
        if (*texturesAmount >= 4) {
            colorSample += colorTexture5.sample(textureSampler, in.textureCoordinate);
            colorSample += colorTexture6.sample(textureSampler, in.textureCoordinate);
        }
        if (*texturesAmount >= 5) {
            colorSample += colorTexture7.sample(textureSampler, in.textureCoordinate);
            colorSample += colorTexture8.sample(textureSampler, in.textureCoordinate);
        }

        return static_cast<float4>(colorSample / static_cast<float>(2 * *texturesAmount - 1));
    }

    /// Rendering type if forwards or backwards
    else {
        if (*texturesAmount >= 2)
            colorSample += colorTexture1.sample(textureSampler, in.textureCoordinate);
        if (*texturesAmount >= 3)
            colorSample += colorTexture2.sample(textureSampler, in.textureCoordinate);
        if (*texturesAmount >= 4)
            colorSample += colorTexture3.sample(textureSampler, in.textureCoordinate);
        if (*texturesAmount >= 5)
            colorSample += colorTexture4.sample(textureSampler, in.textureCoordinate);
        if (*texturesAmount >= 6)
            colorSample += colorTexture5.sample(textureSampler, in.textureCoordinate);
        if (*texturesAmount >= 7)
            colorSample += colorTexture6.sample(textureSampler, in.textureCoordinate);
        if (*texturesAmount >= 8)
            colorSample += colorTexture7.sample(textureSampler, in.textureCoordinate);
        if (*texturesAmount >= 9)
            colorSample += colorTexture8.sample(textureSampler, in.textureCoordinate);

        return static_cast<float4>(colorSample / static_cast<float>(*texturesAmount));
    }

    return static_cast<float4>(colorSample);
}
