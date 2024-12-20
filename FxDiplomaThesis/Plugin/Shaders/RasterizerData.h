#ifndef RasterizerData_h
#define RasterizerData_h

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef struct
{
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
    
} RasterizerData;


#endif /* RasterizerData_h */
