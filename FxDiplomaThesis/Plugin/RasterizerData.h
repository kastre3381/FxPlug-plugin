#ifndef RasterizerData_h
#define RasterizerData_h

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef struct
{
    // The [[position]] attribute of this member indicates that this value is the clip space
    // position of the vertex when this structure is returned from the vertex function
    float4 clipSpacePosition [[position]];
    
    // Since this member does not have a special attribute, the rasterizer interpolates
    // its value with the values of the other triangle vertices and then passes
    // the interpolated value to the fragment shader for each fragment in the triangle
    float2 textureCoordinate;
    
} RasterizerData;


#endif /* RasterizerData_h */
