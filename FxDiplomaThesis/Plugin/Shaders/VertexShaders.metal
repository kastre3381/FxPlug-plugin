using namespace metal;

#include "RasterizerData.h"
#include "ShaderTypes.h"

#pragma mark Vertex Shader
[[vertex]]
RasterizerData vertexShader(uint vertexID [[vertex_id]], constant Vertex2D *vertexArray [[buffer(VI_Vertices)]],
                            constant vector_uint2 *viewportSizePointer [[buffer(VI_ViewportSize)]]) {
    RasterizerData out;

    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    float2 viewportSize = float2(*viewportSizePointer);

    /// Conversion from pixel space to clip space
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);

    out.clipSpacePosition.z = 0.0;
    out.clipSpacePosition.w = 1.0;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    return out;
}
