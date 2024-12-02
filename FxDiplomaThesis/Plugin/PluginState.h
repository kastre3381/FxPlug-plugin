#ifndef PluginState_h
#define PluginState_h

#include "EffectTypes.h"
#include <simd/simd.h>
#include <Metal/Metal.h>

typedef struct
{
    EffectTypes effect;
    float brightness;
    BOOL negative;
    float gammaCorrection;
    float hue;
    float lightness;
    float saturation;
    float temperature;
    int channelType;
    
    int gaussianBlurRadius;
    int kawaseBlurRadius;
    int boxBlurRadius;
    
    float circleBlurRadius;
    float circleBlurLocationX;
    float circleBlurLocationY;
    int circleBlurAmount;
    float circleBlurMixFactor;
    BOOL circleBlurSmooth;
    
    int oilPaintingNoiseSuppression;
    int oilPaintingRadius;
    int oilPaintingLevelOfIntensity;
    BOOL oilPaintingCheapImage;
    
    simd_float2 lensFlarePos;
    simd_float3 lensFlareSunColor;
    BOOL lensFlareShowImage;
    float lensFlareIntensityOfLight;
    float lensFlareStrength;
    float lensFlareStretch;
    float lensFlareBrightness;
    float lensFlareThreshold;
    BOOL lensFlareCheapFlare;
    
    int pixelationSize;
    
    float fishEyeLocX;
    float fishEyeLocY;
    float fishEyeRad;
    float fishEyeAmount;
} PluginState;

#endif /* PluginState_h */
