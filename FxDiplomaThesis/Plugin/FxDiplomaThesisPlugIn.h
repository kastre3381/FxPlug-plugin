#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>
#import "ParameterFlags.h"
#import "Calculations/Matrix.h"
#import "Calculations/MatrixCache.h"
#import "Renderer/Renderer.h"
#import "ParameterManager/ParameterManager.h"
#import <IOSurface/IOSurfaceObjC.h>
#import "ShaderTypes.h"
#import "Device/MetalDeviceCache.h"
#import "PluginState.h"
#import <string>
#import <sstream>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>


@interface FxDiplomaThesisPlugIn : NSObject <FxTileableEffect>
@property (assign) id<PROAPIAccessing> apiManager;
@property (assign) NSArray* menuEntries;
@property (assign) NSArray* channelsEntries;
@property (assign) NSArray* blurEntries;
@property (assign) NSArray* oscEntries;
@property (assign) NSArray* timeTypes;
@property (assign) NSArray* timeEntries;
@property (assign) NSArray* specialEffectsEntries;
@property (assign) MatrixCache<id<MTLBuffer>>* mCache;
@property (assign) FxPoint2D lastFishEyePosition;
@property (assign) FxPoint2D lastCircleBlurPosition;
@property (assign) FxPoint2D lastLensFlarePosition;
@property (assign) TimingRenderTypes typeToRenderEcho;
@property (assign) int numFrames;
@property (assign) float frameDelay;
@end
