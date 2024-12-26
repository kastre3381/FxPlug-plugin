#import <simd/simd.h>

typedef enum VertexInputIndex {
    VI_Vertices = 0,
    VI_ViewportSize = 1
} VertexInputIndex;

typedef enum TextureIndex {
    TI_NoneInputImage = 0,
    TI_BasicInputImage = 1,
    TI_NegativeInputImage = 2,
    TI_GaussianBlurInputImage = 3,
    TI_KawaseBlurInputImage = 4,
    TI_BoxBlurInputImage = 5,
    TI_CircleBlurInputImage = 6,

    TI_TimingEchoInputImage0 = 7,
    TI_TimingEchoInputImage1 = 8,
    TI_TimingEchoInputImage2 = 9,
    TI_TimingEchoInputImage3 = 10,
    TI_TimingEchoInputImage4 = 11,
    TI_TimingEchoInputImage5 = 12,
    TI_TimingEchoInputImage6 = 13,
    TI_TimingEchoInputImage7 = 14,
    TI_TimingEchoInputImage8 = 15,

    TI_LensFlareInputImage = 30,
    
    TI_OilPaintingInputImage = 100,
    TI_PixelationInputImage = 101,
    TI_FishEyeInputImage = 102,
} TextureIndex;

typedef enum FragmentIndexBasic {
    FIB_Brightness = 0,
    FIB_Negative = 1,
    FIB_GammaCorrection = 2,
    FIB_Lightness = 3,
    FIB_Saturation = 4,
    FIB_Temperature = 5,
    FIB_Hue = 6,
    FIB_Channel = 7,
} FragmentIndexBasic;

typedef enum FragmentIndexGaussianBlur {
    FIGB_BlurRadius = 0,
    FIGB_TexelSizeX = 1,
    FIGB_TexelSizeY = 2,
    FIGB_Matrix = 3,
} FragmentIndexGaussianBlur;

typedef enum FragmentIndexKawaseBlur {
    FIKB_BlurRadius = 0,
    FIKB_TexelSizeX = 1,
    FIKB_TexelSizeY = 2,
} FragmentIndexKawaseBlur;

typedef enum FragmentIndexBoxBlur {
    FIBB_BlurRadius = 0,
    FIBB_TexelSizeX = 1,
    FIBB_TexelSizeY = 2,
} FragmentIndexBoxBlur;

typedef enum FragmentIndexCircleBlur {
    FICB_BlurRadius = 0,
    FICB_LocationX = 1,
    FICB_LocationY = 2,
    FICB_Amount = 3,
    FICB_TexelSizeX = 4,
    FICB_TexelSizeY = 5,
    FICB_Mix = 6,
    FICB_Matrix = 7,
    FICB_Smooth = 8,
    FICB_Resolution = 9,
} FragmentIndexCircleBlur;

typedef enum FragmentIndexOilPainting {
    FIOP_Radius = 0,
    FIOP_LevelOfIntencity = 1,
    FIOP_TexelSizeX = 2,
    FIOP_TexelSizeY = 3,
} FragmentIndexOilPainting;

typedef enum FragmentIndexFishEye {
    FIFE_Radius = 0,
    FIFE_LocationX = 1,
    FIFE_LocationY = 2,
    FIFE_Amount = 3,
} FragmentIndexFishEye;

typedef enum FragmentIndexPixelation {
    FIP_Radius = 1,
    FIP_TexelSizeX = 2,
    FIP_TexelSizeY = 3,
    FIP_Width = 4,
    FIP_Height = 5,
} FragmentIndexPixelation;

typedef enum FragmentIndexTimingEcho {
    FITE_TexturesAmount = 0,
    FITE_TimingRenderingType = 1,
} FragmentIndexTimingEcho;

typedef enum FragmentIndexLensFlare {
    FILF_Location = 0,
    FILF_SunColor = 1,
    FILF_Resolution = 2,
    FILF_ShowImage = 3,
    FILF_IntensityOfLight = 4,
    FILF_FlareStrength = 5,
    FILF_CheapFlare = 6,
    FILF_AnflareStretch = 7,
    FILF_AnflareBrightness = 8,
    FILF_AnflareThreshold = 9,
} FragmentIndexLensFlare;


typedef enum FragmentIndexOSC {
    FIOSC_Color = 1,
} FragmentIndexOSC;

typedef enum KernelTextureIndex {
    KTI_Magnidute = 0,
    KTI_OutputTexture = 1,
} KernelTextureIndex;

typedef enum KernelIndexes {
    KI_Magnitude = 0,
    KI_OperatorType = 1,
} KernelIndexes;

typedef struct Vertex2D {
    vector_float2 position;
    vector_float2 textureCoordinate;
} Vertex2D;
