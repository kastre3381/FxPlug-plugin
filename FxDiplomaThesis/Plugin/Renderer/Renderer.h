#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>
#import "../PluginState.h"
#import "ShaderTypes.h"
#import <concepts>

template <typename T>
concept ShaderBindingParameter = std::same_as<T, FragmentIndexBasic> ||
                                 std::same_as<T, FragmentIndexBoxBlur> ||
                                 std::same_as<T, FragmentIndexKawaseBlur> ||
                                 std::same_as<T, FragmentIndexOilPainting> ||
                                 std::same_as<T, FragmentIndexGaussianBlur> ||
                                 std::same_as<T, FragmentIndexPixelation> ||
                                 std::same_as<T, FragmentIndexFishEye> ||
                                 std::same_as<T, FragmentIndexCircleBlur> ||
                                 std::same_as<T, FragmentIndexTimingEcho> ||
                                 std::same_as<T, FragmentIndexLensFlare>;


class Renderer
{
public:
    Renderer(id<MTLRenderCommandEncoder> encoder, id<MTLCommandBuffer> commandBuffer): m_encoder(encoder), m_commandBuffer(commandBuffer)
    {}
    
    Renderer(id<MTLComputeCommandEncoder> encoder, id<MTLCommandBuffer> commandBuffer): m_computeEncoder(encoder), m_commandBuffer(commandBuffer)
    {}
    
    Renderer(const Renderer&) = delete;
    Renderer(Renderer&&) = delete;
    Renderer& operator=(const Renderer&) = delete;
    Renderer operator=(Renderer&&) = delete;
    
    void setFragmentTexture(id<MTLTexture>& tex, TextureIndex index)
    {
        [m_encoder setFragmentTexture:tex
                              atIndex:index];
    }
    
    void setEncoder(id<MTLRenderCommandEncoder> encoder)
    {
        m_encoder = encoder;
    }
    
    id<MTLRenderCommandEncoder> getEncoder() const
    {
        return m_encoder;
    }
    
    id<MTLCommandBuffer> getCommandBuffer() const
    {
        return m_commandBuffer;
    }
    
    void setVertexTexture(id<MTLTexture> tex, TextureIndex index)
    {
        [m_encoder setVertexTexture:tex
                            atIndex:index];
    }
    
    void setRenderPipelineState(id<MTLRenderPipelineState> pipState)
    {
        [m_encoder setRenderPipelineState:pipState];
    }
    
    void endEncoding() const
    {
        [m_encoder endEncoding];
    }
    
    void commitAndWaitUntilCompleted() const
    {
        [m_commandBuffer commit];
        [m_commandBuffer waitUntilCompleted];
    }
    
    void setViewport(MTLViewport viewport) const
    {
        [m_encoder setViewport:viewport];
    }
    
    
    void draw(MTLPrimitiveType type, int offset, int count) const
    {
        [m_encoder drawPrimitives:type
                      vertexStart:offset
                      vertexCount:count];
    }
    
    template<typename T>
    void setVertexBytes(const T* bytes, int size, VertexInputIndex index) const
    {
        [m_encoder setVertexBytes:bytes
                           length:size
                          atIndex:index];
    }
        
    template<typename T, typename U>
    void setFragmentBytes(const T* bytes, int size, U index) requires ShaderBindingParameter<U>
    {
        [m_encoder setFragmentBytes:bytes
                           length:size
                          atIndex:index];
    }
    
    template<typename U>
    void setFragmentBuffer(id<MTLBuffer> bytes, int offset, U index) requires ShaderBindingParameter<U>
    {
        
        [m_encoder setFragmentBuffer:bytes
                              offset:offset
                             atIndex:index];
    }
    
    
private:
    id<MTLRenderCommandEncoder> m_encoder;
    id<MTLComputeCommandEncoder> m_computeEncoder;
    id<MTLCommandBuffer> m_commandBuffer;
};



