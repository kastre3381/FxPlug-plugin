#ifndef ParameterFlags_h
#define ParameterFlags_h

typedef enum ParameterFlags
{
    PF_BrightnessSlider               = 1,
    PF_NegativeButton                 = 2,
    PF_GammaCorrection                = 3,
    PF_Lightness                      = 4,
    PF_Saturation                     = 5,
    PF_Temperature                    = 6,
    PF_Hue                            = 7,
    PF_ResetPoints                    = 8,
    
    
    PF_BlurTypes                      = 20,
    PF_GaussianBlurRadius             = 21,
    PF_KawaseBlurRadius               = 22,
    PF_BoxBlurRadius                  = 23,
    PF_CircleBlurRadius               = 24,
    PF_CircleBlurLocation             = 25,
    PF_CircleBlurAmount               = 26,
    PF_CircleBlurMixFactor            = 27,
    PF_CircleBlurSmooth               = 28,
    
    
    PF_OilPaintingRadius              = 30,
    PF_OilPaintingLevelOfIntensity    = 31,
    PF_OilPaintingNoiseSuppression    = 32,
    
    
    PF_PixelationSize                 = 35,
    
    PF_OSCTypes                       = 40,
    
    
    PF_LensFlareLocation              = 51,
    PF_LensFlareSunColor              = 52,
    PF_LensFlareShowImage             = 53,
    PF_LensFlareIntensityOfLight      = 54,
    PF_LensFlareStrength              = 55,
    PF_LensFlareStretch               = 58,
    PF_LensFlareBrightness            = 59,
    
    
    PF_FishEyeLocation                = 60,
    PF_FishEyeRadius                  = 61,
    PF_FishEyeAmount                  = 62,
    
    
    PF_TimingEchoRenderingTypes       = 80,
    PF_TimingTypes                    = 81,
    PF_TimingEchoGroup                = 82,
    PF_TimingEchoNumOfFramesOneDir    = 83,
    PF_TimingEchoNumOfFramesTwoDir    = 84,
    PF_TimingEchoFrameDelay           = 85,
    
    PF_BasicPosition1                 = 90,
    PF_BasicPosition2                 = 91,
    PF_BasicPosition3                 = 92,
    PF_BasicPosition4                 = 93,
    PF_BasicPosition5                 = 94,
    PF_BasicPosition6                 = 95,
    PF_BasicPosition7                 = 96,
    PF_BasicPosition8                 = 97,
    PF_BasicPosition9                 = 98,
    PF_BasicPosition10                = 99,
    PF_BasicPosition11                = 100,
    PF_BasicPosition12                = 101,
    PF_BasicOSCMenu                   = 102,
    
    PF_EffectTypes                    = 222,
    PF_ChannelTypes                   = 223,
    PF_SpecialEffectsTypes            = 502,
    
    PF_BasicGroup                     = 600,
    PF_BlurGroup                      = 601,
    PF_OilPaintingGroup               = 603,
    PF_OSCGroup                       = 604,
    PF_SpecialEffectGroup             = 605,
    PF_LensFlareGroup                 = 606,
    PF_PixelizationGroup              = 608,
    PF_RGB                            = 609,
    PF_HSL                            = 610,
    PF_FishEyeGroup                   = 611,
    PF_CircleBlurGroup                = 612,
    PF_TimingGroup                    = 613,
} ParameterFlags;

#endif /* ParameterFlags_h */
