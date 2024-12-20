#include <metal_stdlib>
using namespace metal;
#include "ShaderTypes.h"
#include "RasterizerData.h"


float getSun(float2 vec)
{
    return length(vec) < 0.009 ? 1.0 : 0.0;
}


float3 lensFlare(float2 textureCoords, float2 sunPos)
{
    float2 vec = textureCoords - sunPos;
    float2 uvd = textureCoords * length(textureCoords);
    float3 sunflare, lensflare;
    
    float angle = atan2(vec.y, vec.x);
    float distance = pow(length(vec), 0.1);
    
    float f0 = 1.0 / (length(textureCoords-sunPos) * 25.0 + 1.0);
    f0 = pow(f0, 2.0);
    
    f0 = f0 + f0 * (sin((angle + 1.0/18.0) * 12.0) * 0.1 + distance * 0.1 + 0.8);
    
    float f2 = max(1.0/(1.0 + 32.0 * pow(length(uvd + 0.8*sunPos), 2.0)),.0) * 0.25;
    float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*sunPos),2.0)),.0)*00.23;
    float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*sunPos),2.0)),.0)*00.21;

    float2 uvx = mix(textureCoords, uvd, -0.5);

    float f4 = max(0.01-pow(length(uvx+0.4*sunPos),2.4),.0)*6.0;
    float f42 = max(0.01-pow(length(uvx+0.45*sunPos),2.4),.0)*5.0;
    float f43 = max(0.01-pow(length(uvx+0.5*sunPos),2.4),.0)*3.0;

    uvx = mix(textureCoords,uvd,-.4);

    float f5 = max(0.01-pow(length(uvx+0.2*sunPos),5.5),.0)*2.0;
    float f52 = max(0.01-pow(length(uvx+0.4*sunPos),5.5),.0)*2.0;
    float f53 = max(0.01-pow(length(uvx+0.6*sunPos),5.5),.0)*2.0;

    uvx = mix(textureCoords,uvd,-0.5);

    float f6 = max(0.01-pow(length(uvx-0.3*sunPos),1.6),.0)*6.0;
    float f62 = max(0.01-pow(length(uvx-0.325*sunPos),1.6),.0)*3.0;
    float f63 = max(0.01-pow(length(uvx-0.35*sunPos),1.6),.0)*5.0;
    

    sunflare = float3(f0);
    lensflare = float3(f2+f4+f5+f6, f22+f42+f52+f62, f23+f43+f53+f63);

    return sunflare + lensflare;
}

float3 anflares(float2 textCoords, float intensity, float stretch, float brightness)
{
    textCoords.x *= 1.0/(intensity*stretch);
    textCoords.y *= 0.5;
    return float3(smoothstep(0.009, 0.0, length(textCoords)))*brightness;
}


float3 anflares(float2 textCooords, float threshold, float intensity, float stretch, float brightness)
{
    threshold = 1.0 - threshold;
    
    float3 hdr = float3(getSun(textCooords));
    
    hdr = float3(floor(threshold + max(hdr.r, 1.0)));
    
    float i = intensity, is = intensity * stretch;
    
    for(float temp=is; temp>-1.0; temp--)
    {
        float texL = getSun(textCooords + float2(temp/i, 0.0));
        float texR = getSun(textCooords + float2(-temp/i, 0.0));
        
        hdr += floor(threshold + pow(max(texL, texR), 4.0)) * (1.0 - temp/is);
    }
    
    
    return hdr*brightness;
}



#pragma mark Lens Flare Shader
[[fragment]]
float4 fragmentLensFlareShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_LensFlareInputImage) ]],
                               constant float2* location [[ buffer(FILF_Location )]],
                               constant float2* resolution [[ buffer(FILF_Resolution )]],
                               constant float3* sunColor [[ buffer(FILF_SunColor )]],
                               constant bool* showImage [[ buffer(FILF_ShowImage )]],
                               constant float* intensityOfSource [[ buffer(FILF_IntensityOfLight )]],
                               constant float* flareStrength [[ buffer(FILF_FlareStrength )]],
                               constant float* anflareStretch [[ buffer(FILF_AnflareStretch )]],
                               constant float* anflareBrightness [[ buffer(FILF_AnflareBrightness )]]
                               )
{
    
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    float2 pos = *location - 0.5;
    float2 coords = in.textureCoordinate - 0.5;
    float3 col = 0.0, sun = 0.0;
    
    pos.x *= (*resolution).x / (*resolution).y;
    coords.x *= (*resolution).x / (*resolution).y;
    
    
    auto flare = lensFlare(coords* *flareStrength, pos* *flareStrength);
    
    float3 anflare = 0.0;
    
    anflare = pow(anflares(coords-pos, 0.5, *intensityOfSource, *anflareStretch, *anflareBrightness), float3(4.0));

    
    sun += getSun(coords-pos) + (flare + anflare)* *sunColor*2.0;
    col += sun;
    
    
    col = 1.0 - exp(-1.0 * col);
    col = pow(col, float3(1.0/2.2));
    
    if(!*showImage)
        return float4(col*0.8, 1.0);
    
    float4 colorSample = static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));
    
//    float diff = dot(*sunColor - col, *sunColor - col);

    float highDiff = dot(col - 1.0, col - 1.0);
    if(highDiff < 0.02) return float4(col, 1.0);
    
    float highDiff2 = dot((colorSample).rgb - 1.0, (colorSample).rgb - 1.0);
    if(highDiff2 < 0.2) return colorSample;
//    if(diff < 0.1) return float4(mix(col, colorSample.rgb, length(coords - *location)*10), 1.0);
//    if(diff < 0.11) return float4(col, 1.0);
    
    float diff2 = dot(colorSample.rgb - col, colorSample.rgb - col);
    
    return float4(mix(colorSample.rgb, col, diff2), 0.0);
}
