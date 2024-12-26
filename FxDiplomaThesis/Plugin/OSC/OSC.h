#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>
#import <Metal/Metal.h>
#import "../FxDiplomaThesisPlugIn.h"

@interface OSC : NSObject<FxOnScreenControl_v4>
@property (assign) id<PROAPIAccessing> apiManager;
@property (assign) CGPoint mousePosition;
@property (assign) NSSize size;
@property (assign) float smallRadius;
@property (assign) simd_float4 unselectedColorCircleBlur;
@property (assign) simd_float4 selectedColorCircleBlur;
@property (assign) simd_float4 outlineColorCircleBlur;
@property (assign) simd_float4 colorFishEyeLensFlare;
@property (assign) simd_float4 outlineColorFishEyeLensFlare;
@end
