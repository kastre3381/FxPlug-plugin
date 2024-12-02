#import <Metal/Metal.h>
#import <FxPlug/FxPlugSDK.h>
#include "PipelineTypes.h"

@class MetalDeviceCacheItem;

@interface MetalDeviceCache : NSObject
{
    NSMutableArray<MetalDeviceCacheItem*>*    deviceCaches;
}

+ (MetalDeviceCache*)deviceCache;
+ (MTLPixelFormat)MTLPixelFormatForImageTile:(FxImageTile*)imageTile;

- (id<MTLDevice>)deviceWithRegistryID:(uint64_t)registryID;
- (id<MTLRenderPipelineState>)pipelineStateWithRegistryID:(uint64_t)registryID
                                              pixelFormat:(MTLPixelFormat)pixFormat
                                             pipelineType:(PipelineTypes)pipType;
- (id<MTLComputePipelineState>)computePipelineStateWithRegistryID:(uint64_t)registryID
                                              pixelFormat:(MTLPixelFormat)pixFormat
                                             pipelineType:(KernelPipelineTypes)pipType;
- (id<MTLCommandQueue>)commandQueueWithRegistryID:(uint64_t)registryID
                                      pixelFormat:(MTLPixelFormat)pixFormat;
- (void)returnCommandQueueToCache:(id<MTLCommandQueue>)commandQueue;

@end