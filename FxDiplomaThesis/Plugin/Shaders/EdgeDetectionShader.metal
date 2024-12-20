#include <metal_stdlib>
using namespace metal;
#include "ShaderTypes.h"
#include "RasterizerData.h"
#include <metal_atomic>

constant float operatorX[3][3] = {
       { -1.0, 0.0, 1.0 },
       { -2.0, 0.0, 2.0 },
       { -1.0, 0.0, 1.0 }
};

constant float operatorY[3][3] = {
       { -1.0, -2.0, -1.0 },
       { 0.0, 0.0, 0.0 },
       { 1.0, 2.0, 1.0 }
};

[[kernel]]
void computeGradientMax(texture2d<float, access::read> inputTexture [[texture(KTI_Magnidute)]],
                               device atomic_float* maxM [[buffer(KI_Magnitude)]],
                               threadgroup float* sharedGroup [[ threadgroup(0)]],
                               uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= inputTexture.get_width() || gid.y >= inputTexture.get_height()) return;
    
    
    float gx = 0.0, gy = 0.0;
    
    for (int i = -1; i <= 1; i++)
    {
        for (int j = -1; j <= 1; j++)
        {
            float2 pos = float2(gid.x + i, gid.y + j);
            float pixel = dot(inputTexture.read(uint2(pos)).rgb, float3(0.2, 0.6, 0.2));
            gx += pixel * operatorX[i + 1][j + 1];
            gy += pixel * operatorY[i + 1][j + 1];
        }
    }
    
    float magnitude = sqrt(gx * gx + gy * gy);
    
    
    bool updated = false;
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    do {
        float currentMax = atomic_load_explicit(maxM, memory_order_relaxed);
        
        threadgroup_barrier(mem_flags::mem_device);
        if (magnitude > currentMax)
        {
            updated = atomic_compare_exchange_weak_explicit(maxM, &currentMax, magnitude, memory_order_relaxed, memory_order_relaxed);
        }
        else
        {
            updated = true;
        }
    } while (!updated);
}
