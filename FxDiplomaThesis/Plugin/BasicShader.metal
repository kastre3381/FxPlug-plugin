#include <metal_stdlib>
using namespace metal;
#include "ShaderTypes.h"
#include "RasterizerData.h"

float hueToRGB(float temp_1, float temp_2, float temp_Col)
{
    if(temp_Col < 0.0) temp_Col++;
    if(temp_Col > 1.0) temp_Col--;
    if(6.0 * temp_Col < 1.0) return temp_2 + (temp_1 - temp_2) * 6.0 * temp_Col;
    if(2.0 * temp_Col < 1.0) return temp_1;
    if(3.0 * temp_Col < 2.0) return temp_2 + (temp_1 - temp_2) * (2.0/3.0 - temp_Col) * 6.0;
    return temp_2;
}


#pragma mark Brightness Shader
[[fragment]]
float4 fragmentBasicShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_BrightnessInputImage) ]],
                               constant float* brightness [[ buffer(FIB_Brightness) ]],
                               constant bool* negative [[ buffer(FIB_Negative) ]],
                               constant float* gamma [[ buffer(FIB_GammaCorrection) ]],
                               constant float* hue [[ buffer(FIB_Hue) ]],
                               constant float* lightness [[ buffer(FIB_Lightness) ]],
                               constant float* saturation [[ buffer(FIB_Saturation) ]],
                               constant float* temperature [[ buffer(FIB_Temperature) ]],
                               constant int* channel [[ buffer(FIB_Channel)]] )
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    const half hBrightness = static_cast<half>(*brightness);
    colorSample.rgb = clamp(colorSample.rgb * hBrightness, 0.0, 1.0);
    
    if(*negative) colorSample.rgb =  1.0 - colorSample.rgb;

    
    half hGamma = *gamma;
    colorSample.rgb = clamp(pow(colorSample.rgb, 1.0 / hGamma), 0.0, 1.0);
    
    colorSample.r = clamp(colorSample.r + *temperature, 0.0, 1.0);
    colorSample.b = clamp(colorSample.b - *temperature, 0.0, 1.0);
    
    //RGB TO HSL
    float minVal = colorSample.r, maxVal = colorSample.r;
    if(minVal > colorSample.g) minVal = colorSample.g;
    if(minVal > colorSample.b) minVal = colorSample.b;
    if(maxVal < colorSample.g) maxVal = colorSample.g;
    if(maxVal < colorSample.b) maxVal = colorSample.b;
    
    float Lightness = (minVal + maxVal) / 2.0, Saturation, Hue;
    
    if(minVal == maxVal)
    {
        Saturation = 0.0;
        Hue = 0.0;
    }
    else
    {
        if(Lightness < 0.5) Saturation = (maxVal - minVal) / (maxVal + minVal);
        else Saturation = (maxVal - minVal) / (2.0 - maxVal - minVal);
        
        
        if(maxVal == colorSample.r) Hue = (colorSample.g - colorSample.b) / (maxVal - minVal) +
            (colorSample.g < colorSample.b ? 6.0 : 0.0);
        else if(maxVal == colorSample.g) Hue = 2.0 + (colorSample.b - colorSample.r) / (maxVal - minVal);
        else Hue = 4.0 + (colorSample.r - colorSample.g) / (maxVal - minVal);
        
        Hue /= 6.0;
    }
    //END
    
    Hue += *hue;
    Lightness = clamp(Lightness * *lightness, 0.0, 100.0);
    Saturation = clamp(Saturation * *saturation, 0.0, 100.0);
    
    

    
    //HSL TO RGB
    float temporary_1;
    if(Lightness < 0.5) temporary_1 = Lightness * (1.0 + Saturation);
    else temporary_1 = Lightness + Saturation - Lightness * Saturation;
    
    float temporary_2 = 2.0 * Lightness - temporary_1;

    
    colorSample.r = hueToRGB(temporary_1, temporary_2, Hue + 1.0/3.0);
    colorSample.g = hueToRGB(temporary_1, temporary_2, Hue);
    colorSample.b = hueToRGB(temporary_1, temporary_2, Hue - 1.0/3.0);
    //END
    
    switch(*channel)
    {
        case 1:
            return float4(colorSample.r, 0.0, 0.0, colorSample.a);
            
        case 2:
            return float4(0.0, colorSample.g, 0.0, colorSample.a);
            
        case 3:
            return float4(0.0, 0.0, colorSample.b, colorSample.a);
            
        case 4:
            return float4(Hue, Hue, Hue, colorSample.a);
            
        case 5:
            return float4(Saturation, Saturation, Saturation, colorSample.a);
            
        case 6:
            return float4(Lightness, Lightness, Lightness, colorSample.a);
            
        default:
            return static_cast<float4>(colorSample);
    }
}
