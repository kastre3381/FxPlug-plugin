#ifndef PipelineTypes_h
#define PipelineTypes_h

typedef enum PipelineTypes {
    PT_None = 0,
    PT_Basic = 1,
    PT_GaussianBlur = 3,
    PT_KawaseBlur = 4,
    PT_BoxBlur = 5,
    PT_CircleBlur = 6,
    PT_LensFlare = 7,
    
    PT_OilPainting = 100,
    PT_Pixelation = 101,
    PT_FishEye = 102,
    
    PT_Echo = 200,
    PT_OSC = 321,
} PipelineTypes;

typedef enum KernelPipelineTypes {
    KPT_EdgeDetectionCalculateMagnitude = 0,
} KernelPipelineTypes;

#endif 
