#include <metal_stdlib>
using namespace metal;
#include "RasterizerData.h"
#include "ShaderTypes.h"

#pragma mark OSC Shader
[[fragment]]
float4 fragmentOSCShader(RasterizerData in [[stage_in]], constant float4 *color [[buffer(FIOSC_Color)]]) {
    return *color;
}
