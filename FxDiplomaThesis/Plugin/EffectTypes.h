#ifndef EffectTypes_h
#define EffectTypes_h

typedef enum EffectTypes
{
    ET_None                     = 0,
    ET_Basic                    = 1,
    ET_Blur                     = 2,
    ET_SpecialEffect            = 3,
    ET_LensFlare                = 4,
    ET_Timing                   = 5,
    
    ET_GaussianBlur             = 200,
    ET_KawaseBlur               = 201,
    ET_BoxBlur                  = 202,
    ET_CircleBlur               = 203,
    
    ET_OilPainting              = 300,
    ET_Pixelization             = 301,
    ET_FishEye                  = 302,
    
    ET_Echo                     = 500,
} EffectTypes;

typedef enum ChannelTypes
{
    CT_All                      = 0,
    CT_Red                      = 1,
    CT_Green                    = 2,
    CT_Blue                     = 3,
    CT_Hue                      = 4,
    CT_Saturation               = 5,
    CT_Lightness                = 6,
} ChannelTypes;

typedef enum BlurTypes
{
    BT_GaussianBlur             = 0,
    BT_KawaseBlur               = 1,
    BT_BoxBlur                  = 2,
    BT_CircleBlur               = 3,
} BlurTypes;


typedef enum SpecialTypes
{
    ST_OilPainting              = 0,
    ST_Pixelation               = 1,
    ST_FishEye                  = 2,
} SpecialTypes;

typedef enum TimingTypes
{
    TT_Echo                     = 0,
} TimingTypes;

typedef enum TimingRenderTypes
{
    TRT_None                     = 0,
    TRT_Back                     = 1,
    TRT_Front                    = 2,
    TRT_Center                   = 3,
} TimingRenderTypes;

#endif /* EffectTypes_h */
