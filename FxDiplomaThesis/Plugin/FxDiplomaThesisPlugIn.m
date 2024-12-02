#import "FxDiplomaThesisPlugIn.h"

@implementation FxDiplomaThesisPlugIn

//---------------------------------------------------------
// initWithAPIManager:
//
// This method is called when a plug-in is first loaded, and
// is a good point to conduct any checks for anti-piracy or
// system compatibility. Returning NULL means that a plug-in
// chooses not to be accessible for some reason.
//---------------------------------------------------------

- (nullable instancetype)initWithAPIManager:(id<PROAPIAccessing>)newApiManager;
{
    self = [super init];
    if (self != nil)
    {
        _apiManager = newApiManager;
        _menuEntries = @[@"None", @"Basic", @"Blur", @"Special Effects", @"Lens Flare", @"Timing", @"Edge detection"];
        _channelsEntries = @[@"All", @"Red", @"Green", @"Blue", @"Hue", @"Saturation", @"Lightness"];
        _blurEntries = @[@"Gaussian blur", @"Kawase blur", @"Box blur", @"Circle blur"];
        _specialEffectsEntries = @[@"Oil painting", @"Pixelation", @"Fish eye"];
        _oscEntries = @[@"No OSC", @"Rectanle OSC", @"Circle OSC"];
        _timeTypes = @[@"No blending", @"Frames backward", @"Frame forward", @"Frame forward and backward"];
        _timeEntries = @[@"Echo"];
        _mCache = new MatrixCache<id<MTLBuffer>>();
        
        _typeToRenderEcho = TRT_None;
        _numFrames = 1;
        _frameDelay = 0.0;
        
        _lastFishEyePosition.x = 0.5;
        _lastFishEyePosition.y = 0.5;
        
        _lastCircleBlurPosition.x = 0.5;
        _lastCircleBlurPosition.y = 0.5;
        
        _lastLensFlarePosition.x = 0.5;
        _lastLensFlarePosition.y = 0.5;
    }
    return self;
}

//---------------------------------------------------------
// properties
//
// This method should return an NSDictionary defining the
// properties of the effect.
//---------------------------------------------------------


- (BOOL)properties:(NSDictionary * _Nonnull *)properties
             error:(NSError * _Nullable *)error
{
    *properties = @{
                    kFxPropertyKey_MayRemapTime : [NSNumber numberWithBool:NO],
                    kFxPropertyKey_PixelTransformSupport : [NSNumber numberWithInt:kFxPixelTransform_ScaleTranslate],
                    kFxPropertyKey_VariesWhenParamsAreStatic : [NSNumber numberWithBool:NO]
                    };
    
    return YES;
}

//---------------------------------------------------------
// addParametersWithError
//
// This method is where a plug-in defines its list of parameters.
//---------------------------------------------------------

- (BOOL)addParametersWithError:(NSError**)error
{
    id<FxParameterCreationAPI_v5>   paramAPI    = [_apiManager apiForProtocol:@protocol(FxParameterCreationAPI_v5)];
    if (paramAPI == nil)
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to obtain an FxPlug API Object"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_APIUnavailable
                                     userInfo:userInfo];
        
        return NO;
    }

    ParameterManager paramManager;
    
    paramManager.setParamApi(paramAPI);
    
    paramManager.addPopupMenu(@"Filters", PF_EffectTypes, 0, _menuEntries, kFxParameterFlag_DEFAULT);
    
    paramManager.startSubGroup(@"Basic effects", PF_BasicGroup, kFxParameterFlag_HIDDEN);
    {
        paramManager.addPopupMenu(@"Basic::Show channels", PF_ChannelTypes, 0, _channelsEntries, kFxParameterFlag_DEFAULT);
        paramManager.startSubGroup(@"RGB", PF_RGB, kFxParameterFlag_DEFAULT);
        {
            paramManager.addFloatSlider(@"Basic::Brightness strength", PF_BrightnessSlider, 0.0, -100.0, 100.0, -100.0, 100.0, 1.0, kFxParameterFlag_DEFAULT);
            paramManager.addToggleButton(@"Basic::Negative", PF_NegativeButton, FALSE, kFxParameterFlag_DEFAULT);
            paramManager.addFloatSlider(@"Basic::Gamma Correction", PF_GammaCorrection, 0.0, -100.0, 100.0, -100.0, 100.0, 1.0, kFxParameterFlag_DEFAULT);
            paramManager.addFloatSlider(@"Basic::Temperature adjustment", PF_Temperature, 0.0, -100.0, 100.0, -100.0, 100.0, 1.0, kFxParameterFlag_DEFAULT);
        }
        paramManager.endSubGroup();
        
        paramManager.startSubGroup(@"HSL", PF_HSL, kFxParameterFlag_DEFAULT);
        {
            paramManager.addAngleSlider(@"Basic::Hue adjustment", PF_Hue, 0.0, -180.0, 180.0, kFxParameterFlag_DEFAULT);
            paramManager.addFloatSlider(@"Basic::Saturation adjustment", PF_Saturation, 0.0, -100.0, 100.0, -100.0, 100.0, 1.0, kFxParameterFlag_DEFAULT);
            paramManager.addFloatSlider(@"Basic::Lightness adjustment", PF_Lightness, 0.0, -100.0, 100.0, -100.0, 100.0, 1.0, kFxParameterFlag_DEFAULT);
        }
        paramManager.endSubGroup();
    }
    paramManager.endSubGroup();

    
    paramManager.startSubGroup(@"Blur", PF_BlurGroup, kFxParameterFlag_HIDDEN);
    {
        paramManager.addPopupMenu(@"Blur::Type", PF_BlurTypes, 0, _blurEntries, kFxParameterFlag_DEFAULT);
        paramManager.addIntSlider(@"Blur::Gaussian blur radius", PF_GaussianBlurRadius, 0, 0, 20, 0, 20, 1, kFxParameterFlag_DEFAULT);
        paramManager.addIntSlider(@"Blur::Kawase blur radius", PF_KawaseBlurRadius, 0, 0, 20, 0, 20, 1, kFxParameterFlag_HIDDEN);
        paramManager.addIntSlider(@"Blur::Box blur radius", PF_BoxBlurRadius, 0, 0, 20, 0, 20, 1, kFxParameterFlag_HIDDEN);
        paramManager.startSubGroup(@"Circle blur", PF_CircleBlurGroup, kFxParameterFlag_HIDDEN);
        {
            paramManager.addFloatSlider(@"Blur::Circle radius", PF_CircleBlurRadius, 0.5, 0.0, 1.0, 0.0, 1.0, 0.01, kFxParameterFlag_DEFAULT);
            paramManager.addPointParameter(@"Blur::Center location", PF_CircleBlurLocation, -10.0, -10.0, kFxParameterFlag_DEFAULT);
            paramManager.addIntSlider(@"Blur::Blur radius", PF_CircleBlurAmount, 0, 0, 20, 0, 20, 1, kFxParameterFlag_DEFAULT);
            paramManager.addPercentSlider(@"Blur::Mix", PF_CircleBlurMixFactor, 1.0, 0.0, 1.0, 0.0, 1.0, 0.01, kFxParameterFlag_DEFAULT);
            paramManager.addToggleButton(@"Blur::Smooth edges", PF_CircleBlurSmooth, FALSE, kFxParameterFlag_DEFAULT);
        }
        paramManager.endSubGroup();
    }
    paramManager.endSubGroup();

    
    paramManager.startSubGroup(@"Special Effects", PF_SpecialEffectGroup, kFxParameterFlag_HIDDEN);
    {
        paramManager.addPopupMenu(@"Type", PF_SpecialEffectsTypes, 0, _specialEffectsEntries, kFxParameterFlag_DEFAULT);
        paramManager.startSubGroup(@"Oil painting effect", PF_OilPaintingGroup, kFxParameterFlag_DEFAULT);
        {
            paramManager.addIntSlider(@"Oil painting::Radius", PF_OilPaintingRadius, 0, 0, 20, 0, 20, 1, kFxParameterFlag_DEFAULT);
            paramManager.addIntSlider(@"Oil painting::Level of intensity", PF_OilPaintingLevelOfIntensity, 0, 0, 255, 0, 255, 1, kFxParameterFlag_DEFAULT);
            paramManager.addIntSlider(@"Oil painting::Noise suppression", PF_OilPaintingNoiseSuppression, 0, 0, 20, 0, 20, 1, kFxParameterFlag_DEFAULT);
        }
        paramManager.endSubGroup();
        
        paramManager.startSubGroup(@"Pixelation", PF_PixelizationGroup, kFxParameterFlag_HIDDEN);
        {
            paramManager.addIntSlider(@"Pixelation::Pixel size", PF_PixelationSize, 0, 0, 40, 0, 40, 1, kFxParameterFlag_DEFAULT);
        }
        paramManager.endSubGroup();
        
        paramManager.startSubGroup(@"Fish eye", PF_FishEyeGroup, kFxParameterFlag_HIDDEN);
        {
            paramManager.addPointParameter(@"Fish eye::Center position", PF_FishEyeLocation, -10.0, -10.0, kFxParameterFlag_DEFAULT);
            paramManager.addFloatSlider(@"Fish eye::Radius", PF_FishEyeRadius, 1.0, 0.0, 2.0, 0.0, 2.0, 0.1, kFxParameterFlag_DEFAULT);
            paramManager.addFloatSlider(@"Fish eye::Amount", PF_FishEyeAmount, 0.0, -50.0, 50.0, -50.0, 50.0, 0.5, kFxParameterFlag_DEFAULT);
        }
        paramManager.endSubGroup();
    }
    paramManager.endSubGroup();
    
    
    paramManager.startSubGroup(@"Lens Flare", PF_LensFlareGroup, kFxParameterFlag_HIDDEN);
    {
        paramManager.addPointParameter(@"Lens Flare::Location", PF_LensFlareLocation, -10.0, -10.0, kFxParameterFlag_DEFAULT);
        paramManager.addColorPicker(@"Lens Flare::Sun Color", PF_LensFlareSunColor, 0.643, 0.494, 0.867, kFxParameterFlag_DEFAULT);
        paramManager.addToggleButton(@"Lens Flare::Show frame", PF_LensFlareShowImage, FALSE, kFxParameterFlag_DEFAULT);
        paramManager.addFloatSlider(@"Lens Flare::Flare strength", PF_LensFlareStrength, 1.0, 0.1, 5.0, 0.1, 5.0, 0.01, kFxParameterFlag_DEFAULT);
        paramManager.addFloatSlider(@"Lens Flare::Anflare intensity", PF_LensFlareIntensityOfLight, 400.0, 200.0, 800.0, 200.0, 800.0, 1.0, kFxParameterFlag_DEFAULT);
        paramManager.addFloatSlider(@"Lens Flare::Anflare stretch", PF_LensFlareStretch, 0.8, 0.0, 1.0, 0.0, 1.0, 0.01, kFxParameterFlag_DEFAULT);
        paramManager.addFloatSlider(@"Lens Flare::Anflare brightness", PF_LensFlareBrightness, 0.1, 0.0, 1.0, 0.0, 1.0, 0.01, kFxParameterFlag_DEFAULT);
        paramManager.addToggleButton(@"Lens Flare::Cheap flare", PF_LensFlareCheapFlare, FALSE, kFxParameterFlag_DEFAULT);
        paramManager.addFloatSlider(@"Lens Flare::Anflare threshold", PF_LensFlareThreshold, 0.5, 0.01, 1.0, 0.01, 1.0, 0.01, kFxParameterFlag_DEFAULT);
    }
    paramManager.endSubGroup();
    
    paramManager.startSubGroup(@"Timing", PF_TimingGroup, kFxParameterFlag_HIDDEN);
    {
        paramManager.addPopupMenu(@"Timing::Effect type", PF_TimingTypes, 0, _timeEntries, kFxParameterFlag_DEFAULT);
        paramManager.startSubGroup(@"Echo", PF_TimingEchoGroup, kFxParameterFlag_DEFAULT);
        {
            paramManager.addPopupMenu(@"Echo::Rendering type", PF_TimingEchoRenderingTypes, 0, _timeTypes, kFxParameterFlag_DEFAULT);
            paramManager.addIntSlider(@"Echo::Number of frames", PF_TimingEchoNumOfFramesOneDir, 1, 1, 9, 1, 9, 1, kFxParameterFlag_HIDDEN);
            paramManager.addIntSlider(@"Echo::Number of frames", PF_TimingEchoNumOfFramesTwoDir, 1, 1, 5, 1, 5, 2, kFxParameterFlag_HIDDEN);
            paramManager.addFloatSlider(@"Echo::Frame delay", PF_TimingEchoFrameDelay, 0.0, 0.0, 0.5, 0.0, 0.5, 0.01, kFxParameterFlag_HIDDEN);
        }
        paramManager.endSubGroup();
    }
    paramManager.endSubGroup();
    
    
    return YES;
}

- (BOOL)parameterChanged:(UInt32)paramID
                  atTime:(CMTime)time
                   error:(NSError * _Nullable *)error
{
    id<FxParameterRetrievalAPI_v6> retrievalAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    id<FxParameterSettingAPI_v6> settingsAPI = [_apiManager apiForProtocol:@protocol(FxParameterSettingAPI_v6)];
    
    ParameterManager paramManager;
    paramManager.setSettingsApi(settingsAPI);
    paramManager.setRetrievalApi(retrievalAPI);
    
    int menuVal, blurMenu, specialMenu, timingMenu, timingRenderingMenu;
    paramManager.getIntValue(&menuVal, PF_EffectTypes, time);
    paramManager.getIntValue(&blurMenu, PF_BlurTypes, time);
    paramManager.getIntValue(&specialMenu, PF_SpecialEffectsTypes, time);
    paramManager.getIntValue(&timingMenu, PF_TimingTypes, time);
    paramManager.getIntValue(&timingRenderingMenu, PF_TimingEchoRenderingTypes, time);
    
    if(paramID == PF_EffectTypes)
    {
        
        paramManager.hide(PF_BasicGroup);
        paramManager.hide(PF_BlurGroup);
        paramManager.hide(PF_SpecialEffectGroup);
        paramManager.hide(PF_LensFlareGroup);
        paramManager.hide(PF_TimingGroup);
        
        if(menuVal == ET_SpecialEffect && specialMenu == ST_FishEye)
        {
            paramManager.setPointValues(_lastFishEyePosition.x, _lastFishEyePosition.y, PF_FishEyeLocation, time);
        }
        else
        {
            paramManager.setPointValues(-10.0, -10.0, PF_FishEyeLocation, time);
        }
        
        if(menuVal == ET_Blur && blurMenu == BT_CircleBlur)
        {
            paramManager.setPointValues(_lastCircleBlurPosition.x, _lastCircleBlurPosition.y, PF_CircleBlurLocation, time);
        }
        else
        {
            paramManager.setPointValues(-10.0, -10.0, PF_CircleBlurLocation, time);
        }
        
        if(menuVal == ET_LensFlare)
        {
            paramManager.setPointValues(_lastLensFlarePosition.x, _lastLensFlarePosition.y, PF_LensFlareLocation, time);
        }
        else
        {
            paramManager.setPointValues(-10.0, -10.0, PF_LensFlareLocation, time);
        }
        
        switch (menuVal)
        {
            case ET_Basic:
            {
                paramManager.show(PF_BasicGroup);
                break;
            }
            
            case ET_Blur:
            {
                paramManager.show(PF_BlurGroup);
                break;
            }
                
            case ET_SpecialEffect:
            {
                paramManager.show(PF_SpecialEffectGroup);
                break;
            }
                
            case ET_LensFlare:
            {
                paramManager.show(PF_LensFlareGroup);
                break;
            }
                
            case ET_Timing:
            {
                paramManager.show(PF_TimingGroup);
                break;
            }
            
            
            default:
                break;
        }
    }
    
    else if(paramID == PF_BlurTypes)
    {
        paramManager.hide(PF_GaussianBlurRadius);
        paramManager.hide(PF_KawaseBlurRadius);
        paramManager.hide(PF_BoxBlurRadius);
        paramManager.hide(PF_CircleBlurGroup);

        if(blurMenu == BT_CircleBlur)
        {
            paramManager.setPointValues(_lastCircleBlurPosition.x, _lastCircleBlurPosition.y, PF_CircleBlurLocation, time);
        }
        else
        {
            paramManager.setPointValues(-10.0, -10.0, PF_CircleBlurLocation, time);
        }
        
        switch(blurMenu)
        {
            case (BT_GaussianBlur):
            {
                paramManager.show(PF_GaussianBlurRadius);
                break;
            }
                
                
            case (BT_KawaseBlur):
            {
                paramManager.show(PF_KawaseBlurRadius);
                break;
            }
                
            case (BT_BoxBlur):
            {
                paramManager.show(PF_BoxBlurRadius);
                break;
            }
                
            case (BT_CircleBlur):
            {
                paramManager.show(PF_CircleBlurGroup);
                break;
            }
                
            default:
                break;
        }
    }
    
    
    else if(paramID == PF_SpecialEffectsTypes)
    {
        paramManager.hide(PF_OilPaintingGroup);
        paramManager.hide(PF_PixelizationGroup);
        paramManager.hide(PF_FishEyeGroup);
        
        if(specialMenu == ST_FishEye)
        {
            paramManager.setPointValues(_lastFishEyePosition.x, _lastFishEyePosition.y, PF_FishEyeLocation, time);
        }
        else
        {
            paramManager.setPointValues(-10.0, -10.0, PF_FishEyeLocation, time);
        }
        
        switch(specialMenu)
        {
            case (ST_OilPainting):
            {
                paramManager.show(PF_OilPaintingGroup);
                break;
            }
                
            case (ST_Pixelation):
            {
                paramManager.show(PF_PixelizationGroup);
                break;
            }
                
            case (ST_FishEye):
            {
                paramManager.show(PF_FishEyeGroup);
                break;
            }
                
            default:
                break;
        }
    }


    else if(paramID == PF_TimingTypes)
    {
        paramManager.hide(PF_TimingEchoGroup);
        
        switch(timingMenu)
        {
            case (TT_Echo):
            {
                paramManager.show(PF_TimingEchoGroup);
                break;
            }
                
            default:
                break;
        }
    }
    
    else if(paramID == PF_TimingEchoRenderingTypes)
    {
        paramManager.hide(PF_TimingEchoNumOfFramesOneDir);
        paramManager.hide(PF_TimingEchoNumOfFramesTwoDir);
        paramManager.hide(PF_TimingEchoFrameDelay);
        
        switch (timingRenderingMenu)
        {
            case (TRT_None):
            {
                break;
            }
                
            case (TRT_Center):
            {
                paramManager.show(PF_TimingEchoNumOfFramesTwoDir);
                paramManager.show(PF_TimingEchoFrameDelay);
                break;
            }
                
            default:
            {
                paramManager.show(PF_TimingEchoNumOfFramesOneDir);
                paramManager.show(PF_TimingEchoFrameDelay);
                break;
            }
                
        }
    }
    
    else if(paramID == PF_LensFlareCheapFlare)
    {
        BOOL temp = FALSE;
        paramManager.getBoolValue(&temp, PF_LensFlareCheapFlare, time);
        
        if(temp == true) paramManager.hide(PF_LensFlareThreshold);
        else paramManager.show(PF_LensFlareThreshold);
    }
    
    else if(paramID == PF_FishEyeLocation)
    {
        paramManager.getPointValues(&_lastFishEyePosition.x, &_lastFishEyePosition.y, PF_FishEyeLocation, time);
    }
    
    else if(paramID == PF_CircleBlurLocation)
    {
        paramManager.getPointValues(&_lastCircleBlurPosition.x, &_lastCircleBlurPosition.y, PF_CircleBlurLocation, time);
    }
    
    else if(paramID == PF_LensFlareLocation)
    {
        paramManager.getPointValues(&_lastLensFlarePosition.x, &_lastLensFlarePosition.y, PF_LensFlareLocation, time);
    }
    
    
    
    return YES;
}


//---------------------------------------------------------
// pluginState:atTime:quality:error
//
// Your plug-in should get its parameter values, do any calculations it needs to
// from those values, and package up the result to be used later with rendering.
// The host application will call this method before rendering. The
// FxParameterRetrievalAPI* is valid during this call. Use it to get the values of
// your plug-in's parameters, then put those values or the results of any calculations
// you need to do with those parameters to render into an NSData that you return
// to the host application. The host will pass it back to you during subsequent calls.
// Do not re-use the NSData; always create a new one as this method may be called
// on multiple threads at the same time.
//---------------------------------------------------------

- (BOOL)pluginState:(NSData**)pluginState
             atTime:(CMTime)renderTime
            quality:(FxQuality)qualityLevel
              error:(NSError**)error
{
    BOOL    succeeded = NO;
    id<FxParameterRetrievalAPI_v6>  paramGetAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    if (paramGetAPI != nil)
    {
        ParameterManager paramManager;
        paramManager.setRetrievalApi(paramGetAPI);
        
        int effectType, blurType, specialType, timingType, timingRenderingtype;
        paramManager.getIntValue(&effectType, PF_EffectTypes, renderTime);
        paramManager.getIntValue(&blurType, PF_BlurTypes, renderTime);
        paramManager.getIntValue(&specialType, PF_SpecialEffectsTypes, renderTime);
        paramManager.getIntValue(&timingType, PF_TimingTypes, renderTime);
        paramManager.getIntValue(&timingRenderingtype, PF_TimingEchoRenderingTypes, renderTime);
        
        PluginState state;
        paramManager.getIntValue(&state.channelType, PF_ChannelTypes, renderTime);
        paramManager.getIntValue(&state.gaussianBlurRadius, PF_GaussianBlurRadius, renderTime);
        paramManager.getIntValue(&state.kawaseBlurRadius, PF_KawaseBlurRadius, renderTime);
        paramManager.getIntValue(&state.boxBlurRadius, PF_BoxBlurRadius, renderTime);
        paramManager.getIntValue(&state.oilPaintingRadius, PF_OilPaintingRadius, renderTime);
        paramManager.getIntValue(&state.oilPaintingLevelOfIntensity, PF_OilPaintingLevelOfIntensity, renderTime);
        paramManager.getIntValue(&state.oilPaintingNoiseSuppression, PF_OilPaintingNoiseSuppression, renderTime);
        paramManager.getIntValue(&state.pixelationSize, PF_PixelationSize, renderTime);
        paramManager.getIntValue(&state.circleBlurAmount, PF_CircleBlurAmount, renderTime);

        paramManager.getFloatValue(&state.brightness, PF_BrightnessSlider, renderTime);
        paramManager.getFloatValue(&state.gammaCorrection, PF_GammaCorrection, renderTime);
        paramManager.getFloatValue(&state.hue, PF_Hue, renderTime);
        paramManager.getFloatValue(&state.lightness, PF_Lightness, renderTime);
        paramManager.getFloatValue(&state.saturation, PF_Saturation, renderTime);
        paramManager.getFloatValue(&state.temperature, PF_Temperature, renderTime);
        paramManager.getFloatValue(&state.fishEyeRad, PF_FishEyeRadius, renderTime);
        paramManager.getFloatValue(&state.fishEyeAmount, PF_FishEyeAmount, renderTime);
        paramManager.getFloatValue(&state.circleBlurMixFactor, PF_CircleBlurMixFactor, renderTime);
        paramManager.getFloatValue(&state.circleBlurRadius, PF_CircleBlurRadius, renderTime);
        paramManager.getFloatValue(&state.lensFlareIntensityOfLight, PF_LensFlareIntensityOfLight, renderTime);
        paramManager.getFloatValue(&state.lensFlareStrength, PF_LensFlareStrength, renderTime);
        paramManager.getFloatValue(&state.lensFlareThreshold, PF_LensFlareThreshold, renderTime);
        paramManager.getFloatValue(&state.lensFlareStretch, PF_LensFlareStretch, renderTime);
        paramManager.getFloatValue(&state.lensFlareBrightness, PF_LensFlareBrightness, renderTime);

        paramManager.getBoolValue(&state.negative, PF_NegativeButton, renderTime);
        paramManager.getBoolValue(&state.circleBlurSmooth, PF_CircleBlurSmooth, renderTime);
        paramManager.getBoolValue(&state.lensFlareShowImage, PF_LensFlareShowImage, renderTime);
        paramManager.getBoolValue(&state.lensFlareCheapFlare, PF_LensFlareCheapFlare, renderTime);
        
        paramManager.getPointValues(&state.fishEyeLocX, &state.fishEyeLocY, PF_FishEyeLocation, renderTime);
        paramManager.getPointValues(&state.circleBlurLocationX, &state.circleBlurLocationY, PF_CircleBlurLocation, renderTime);
        
        if(state.brightness < 0.0) state.brightness = (state.brightness + 100.0) / 100.0;
        else state.brightness = (state.brightness + 10.0) / 10.0;
        
        float r, g, b;
        paramManager.getColorValue(&r, &g, &b, PF_LensFlareSunColor, renderTime);
        state.lensFlareSunColor = simd_make_float3(r, g, b);
        
        float x, y;
        paramManager.getPointValues(&x, &y, PF_LensFlareLocation, renderTime);
        state.lensFlarePos = simd_make_float2(x, y);
        
        NSLog(@"%f\t%f", state.lensFlarePos.x, state.lensFlarePos.y);

        if(state.gammaCorrection < 0.0) state.gammaCorrection = (state.gammaCorrection + 101.0) / 101.0;
        else state.gammaCorrection = (state.gammaCorrection + 30.0) / 30.0;

        if(state.lightness < 0.0) state.lightness = (state.lightness + 100.0) / 100.0;
        else state.lightness = (state.lightness + 30.0) / 30.0;
        
        if(state.saturation < 0.0) state.saturation = (state.saturation + 100.0) / 100.0;
        else state.saturation = (state.saturation + 30.0) / 30.0;
        
        state.temperature /= 3000.0;
        if(state.fishEyeAmount < 0.0) state.fishEyeAmount /= 100.0;
        else state.fishEyeAmount /= 10.0;
        
        if(effectType == ET_Blur)
        {
            if(blurType == BT_GaussianBlur) state.effect = ET_GaussianBlur;
            else if (blurType == BT_KawaseBlur) state.effect = ET_KawaseBlur;
            else if(blurType == BT_BoxBlur) state.effect = ET_BoxBlur;
            else if(blurType == BT_CircleBlur) state.effect = ET_CircleBlur;
        }
        
        else if(effectType == ET_SpecialEffect)
        {
            if(specialType == ST_OilPainting) state.effect = ET_OilPainting;
            else if(specialType == ST_Pixelation) state.effect = ET_Pixelization;
            else if(specialType == ST_FishEye) state.effect = ET_FishEye;
        }
        
        else if(effectType == ET_Timing)
        {
            if(timingType == TT_Echo) state.effect = ET_Echo;
        }
        
        else state.effect = static_cast<EffectTypes>(effectType);
        
        
        if(state.effect == ET_Echo)
        {
            if(timingRenderingtype == TRT_None)
            {
                _numFrames = 1;
                _frameDelay = 0.0;
                _typeToRenderEcho = TRT_None;
            }
            else if(timingRenderingtype == TRT_Center)
            {
                paramManager.getFloatValue(&_frameDelay, PF_TimingEchoFrameDelay, renderTime);
                paramManager.getIntValue(&_numFrames, PF_TimingEchoNumOfFramesTwoDir, renderTime);
                _typeToRenderEcho = TRT_Center;
            }
            else
            {
                paramManager.getFloatValue(&_frameDelay, PF_TimingEchoFrameDelay, renderTime);
                paramManager.getIntValue(&_numFrames, PF_TimingEchoNumOfFramesOneDir, renderTime);
                _typeToRenderEcho = (timingRenderingtype == TRT_Back ? TRT_Back : TRT_Front);
            }
        }
        
        else
        {
            _numFrames = 1;
            _frameDelay = 0.0;
            _typeToRenderEcho = TRT_None;
        }
        
        
        *pluginState = [NSData dataWithBytes:&state
                                      length:sizeof(state)];
        
        if (*pluginState != nil) {
            succeeded = YES;
        }
        

    }
    else
    {
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_ThirdPartyDeveloperStart + 20
                                     userInfo:@{
                                                NSLocalizedDescriptionKey :
                                                    @"Unable to retrieve FxParameterRetrievalAPI_v6 in \
                                                    [-pluginStateAtTime:]" }];
        
    }
    
    return succeeded;
}

//---------------------------------------------------------
// destinationImageRect:sourceImages:destinationImage:pluginState:atTime:error
//
// This method will calculate the rectangular bounds of the output
// image given the various inputs and plug-in state
// at the given render time.
// It will pass in an array of images, the plug-in state
// returned from your plug-in's -pluginStateAtTime:error: method,
// and the render time.
//---------------------------------------------------------

- (BOOL)destinationImageRect:(FxRect *)destinationImageRect
                sourceImages:(NSArray<FxImageTile *> *)sourceImages
            destinationImage:(nonnull FxImageTile *)destinationImage
                 pluginState:(NSData *)pluginState
                      atTime:(CMTime)renderTime
                       error:(NSError * _Nullable *)outError
{
    if (sourceImages.count < 1)
    {
        NSLog (@"No inputImages list");
        return NO;
    }
    
    // In the case of a filter that only changed RGB values,
    // the output rect is the same as the input rect.
    *destinationImageRect = sourceImages [ 0 ].imagePixelBounds;
    
    return YES;
  
}

//---------------------------------------------------------
// sourceTileRect:sourceImageIndex:sourceImages:destinationTileRect:destinationImage:pluginState:atTime:error
//
// Calculate tile of the source image we need
// to render the given output tile.
//---------------------------------------------------------

- (BOOL)sourceTileRect:(FxRect *)sourceTileRect
      sourceImageIndex:(NSUInteger)sourceImageIndex
          sourceImages:(NSArray<FxImageTile *> *)sourceImages
   destinationTileRect:(FxRect)destinationTileRect
      destinationImage:(FxImageTile *)destinationImage
           pluginState:(NSData *)pluginState
                atTime:(CMTime)renderTime
                 error:(NSError * _Nullable *)outError
{
    // Since this is a color-only filter, the input tile will be the same size as the output tile
    *sourceTileRect = destinationTileRect;
    
    return YES;
}




- (BOOL)scheduleInputs:(NSArray<FxImageTileRequest*>* _Nullable * _Nullable)inputImageRequests
       withPluginState:(NSData* _Nullable)pluginState
                atTime:(CMTime)renderTime
                 error:(NSError**)error
{
    NSMutableArray<FxImageTileRequest *> *requests = [NSMutableArray array];
    
    FxImageTileRequest *currentFrameRequest = [[FxImageTileRequest alloc]
                                                initWithSource:kFxImageTileRequestSourceEffectClip
                                                time:renderTime
                                                includeFilters:YES
                                                parameterID:0];
    [requests addObject:currentFrameRequest];
    
    if(_typeToRenderEcho == TRT_Center)
    {
        for(float i = -(_numFrames-1); i < _numFrames; i++)
        {
            if(i!=0)
            {
                CMTime nextFrameTime = CMTimeAdd(renderTime, CMTimeMake(renderTime.timescale * i *_frameDelay, renderTime.timescale));
                
                FxImageTileRequest *nextFrameRequest = [[FxImageTileRequest alloc]
                                                        initWithSource:kFxImageTileRequestSourceEffectClip
                                                        time:nextFrameTime
                                                        includeFilters:YES
                                                        parameterID:0];
                [requests addObject:nextFrameRequest];
            }
        }
    }

    else if(_typeToRenderEcho == TRT_Front)
    {
        for(float i = 1; i < _numFrames; i++)
        {
            CMTime nextFrameTime = CMTimeAdd(renderTime, CMTimeMake(renderTime.timescale * i *_frameDelay, renderTime.timescale));
            
            FxImageTileRequest *nextFrameRequest = [[FxImageTileRequest alloc]
                                                     initWithSource:kFxImageTileRequestSourceEffectClip
                                                     time:nextFrameTime
                                                     includeFilters:YES
                                                     parameterID:0];
            [requests addObject:nextFrameRequest];
        }
    }
    
    else if(_typeToRenderEcho == TRT_Back)
    {
        NSLog(@"numFrames %d", _numFrames);
        
        for(float i = -(_numFrames-1); i <0; i++)
        {
            CMTime nextFrameTime = CMTimeAdd(renderTime, CMTimeMake(renderTime.timescale * i *_frameDelay, renderTime.timescale));
            
            FxImageTileRequest *nextFrameRequest = [[FxImageTileRequest alloc]
                                                     initWithSource:kFxImageTileRequestSourceEffectClip
                                                     time:nextFrameTime
                                                     includeFilters:YES
                                                     parameterID:0];
            [requests addObject:nextFrameRequest];
        }
    }
    
    

    *inputImageRequests = requests;

    return YES;
}



//---------------------------------------------------------
// renderDestinationImage:sourceImages:pluginState:atTime:error:
//
// The host will call this method when it wants your plug-in to render an image
// tile of the output image. It will pass in each of the input tiles needed as well
// as the plug-in state needed for the calculations. Your plug-in should do all its
// rendering in this method. It should not attempt to use the FxParameterRetrievalAPI*
// object as it is invalid at this time. Note that this method will be called on
// multiple threads at the same time.
//---------------------------------------------------------



- (BOOL)renderDestinationImage:(FxImageTile *)destinationImage
                  sourceImages:(NSArray<FxImageTile *> *)sourceImages
                   pluginState:(NSData *)pluginState
                        atTime:(CMTime)renderTime
                         error:(NSError * _Nullable *)outError
{
    if ((pluginState == nil) || (sourceImages [ 0 ].ioSurface == nil) || (destinationImage.ioSurface == nil))
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Invalid plugin state received from host"
                                        };
        if (outError != NULL)
            *outError = [NSError errorWithDomain:FxPlugErrorDomain
                                            code:kFxError_InvalidParameter
                                        userInfo:userInfo];
        return NO;
    }
    
    PluginState state;
    [pluginState getBytes:&state
                   length:sizeof(state)];
    
    MetalDeviceCache*  deviceCache     = [MetalDeviceCache deviceCache];
    MTLPixelFormat     pixelFormat     = [MetalDeviceCache MTLPixelFormatForImageTile:destinationImage];
    id<MTLCommandQueue> commandQueue   = [deviceCache commandQueueWithRegistryID:sourceImages[0].deviceRegistryID
                                                                     pixelFormat:pixelFormat];
    if (commandQueue == nil)
    {
        return NO;
    }
    
    id<MTLCommandBuffer>    commandBuffer   = [commandQueue commandBuffer];
    commandBuffer.label = @"DynamicRegXPC Command Buffer";
    [commandBuffer enqueue];
    
    id<MTLTexture>  inputTexture    = [sourceImages[0] metalTextureForDevice:[deviceCache deviceWithRegistryID:sourceImages[0].deviceRegistryID]];
    id<MTLTexture>  outputTexture   = [destinationImage metalTextureForDevice:[deviceCache deviceWithRegistryID:destinationImage.deviceRegistryID]];
        
    
    
    
    MTLRenderPassColorAttachmentDescriptor* colorAttachmentDescriptor   = [[MTLRenderPassColorAttachmentDescriptor alloc] init];
    colorAttachmentDescriptor.texture = outputTexture;
    colorAttachmentDescriptor.clearColor = MTLClearColorMake(1.0, 0.5, 0.0, 1.0);
    colorAttachmentDescriptor.loadAction = MTLLoadActionClear;
    MTLRenderPassDescriptor*    renderPassDescriptor    = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments [ 0 ] = colorAttachmentDescriptor;
    id<MTLRenderCommandEncoder>   commandEncoder  = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    // Rendering
    float   outputWidth     = (float)(destinationImage.tilePixelBounds.right - destinationImage.tilePixelBounds.left);
    float   outputHeight    = (float)(destinationImage.tilePixelBounds.top - destinationImage.tilePixelBounds.bottom);
    Vertex2D    vertices[]  = {
        { {  static_cast<float>(outputWidth / 2.0), static_cast<float>(-outputHeight / 2.0) }, { 1.0, 1.0 } },
        { { static_cast<float>(-outputWidth / 2.0), static_cast<float>(-outputHeight / 2.0) }, { 0.0, 1.0 } },
        { {  static_cast<float>(outputWidth / 2.0),  static_cast<float>(outputHeight / 2.0) }, { 1.0, 0.0 } },
        { { static_cast<float>(-outputWidth / 2.0),  static_cast<float>(outputHeight / 2.0) }, { 0.0, 0.0 } }
    };
    
    simd_uint2  viewportSize = {
        (unsigned int)(outputWidth),
        (unsigned int)(outputHeight)
    };
    
    
    MTLViewport viewport    = {
        0, 0, outputWidth, outputHeight, -1.0, 1.0
    };
    
    simd_float2 resolution = simd_make_float2(outputWidth, outputHeight);
    
    [commandEncoder setViewport:viewport];
    
    Renderer renderer(commandEncoder, commandBuffer);
    renderer.setViewport(viewport);
    renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
    renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
    
    float texelSizeX = 1.0/static_cast<float>(outputTexture.width);
    float texelSizeY = 1.0/static_cast<float>(outputTexture.height);

    
#pragma mark -
#pragma mark Basic effect
    switch (state.effect) {
        case (ET_Basic):
        {
            auto pipState = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                 pixelFormat:pixelFormat
                                                 pipelineType:PT_Basic];
            
            renderer.setRenderPipelineState(pipState);
            renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
            renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
            renderer.setFragmentTexture(inputTexture, TI_BrightnessInputImage);
            renderer.setFragmentBytes(&state.channelType, sizeof(state.channelType), FIB_Channel);
            renderer.setFragmentBytes(&state.brightness, sizeof(state.brightness), FIB_Brightness);
            renderer.setFragmentBytes(&state.gammaCorrection, sizeof(state.gammaCorrection), FIB_GammaCorrection);
            renderer.setFragmentBytes(&state.hue, sizeof(state.hue), FIB_Hue);
            renderer.setFragmentBytes(&state.lightness, sizeof(state.lightness), FIB_Lightness);
            renderer.setFragmentBytes(&state.saturation, sizeof(state.saturation), FIB_Saturation);
            renderer.setFragmentBytes(&state.temperature, sizeof(state.temperature), FIB_Temperature);
            renderer.setFragmentBytes(&state.negative, sizeof(state.negative), FIB_Negative);
            
            
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();
            
            break;
        }
            

#pragma mark -
#pragma mark Gaussian Blur effect
        case (ET_GaussianBlur):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_GaussianBlur];
            
            renderer.setRenderPipelineState(pipelineState);
            renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
            renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
            renderer.setFragmentTexture(inputTexture, TI_GaussianBlurInputImage);
            renderer.setFragmentBytes(&texelSizeX, sizeof(texelSizeX), FIGB_TexelSizeX);
            renderer.setFragmentBytes(&texelSizeY, sizeof(texelSizeY), FIGB_TexelSizeY);
            renderer.setFragmentBytes(&state.gaussianBlurRadius, sizeof(state.gaussianBlurRadius), FIGB_BlurRadius);

            if(!_mCache->contains(state.gaussianBlurRadius)) _mCache->putMatrixBuffer(state.gaussianBlurRadius);
                
            renderer.setFragmentBuffer(_mCache->get(state.gaussianBlurRadius), 0, FIGB_Matrix);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();

            break;
        }
            
#pragma mark -
#pragma mark Kawase Blur effect
        case (ET_KawaseBlur):
        {
            if(state.kawaseBlurRadius == 0)
            {
                id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                              pixelFormat:pixelFormat
                                                             pipelineType:PT_None];
                
                renderer.setRenderPipelineState(pipelineState);
                renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
                renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
                renderer.setFragmentTexture(inputTexture, TI_NoneInputImage);
                renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
                renderer.endEncoding();
            }
            else
            {
                int tempRad = 1;
                id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                              pixelFormat:pixelFormat
                                                             pipelineType:PT_KawaseBlur];
                renderer.setRenderPipelineState(pipelineState);
                renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
                renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
                renderer.setFragmentTexture(inputTexture, TI_KawaseBlurInputImage);
                renderer.setFragmentBytes(&texelSizeX, sizeof(texelSizeX), FIKB_TexelSizeX);
                renderer.setFragmentBytes(&texelSizeY, sizeof(texelSizeY), FIKB_TexelSizeY);
                renderer.setFragmentBytes(&tempRad, sizeof(tempRad), FIKB_BlurRadius);
                renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
                renderer.endEncoding();
                
                tempRad = 2;
                while(tempRad++ <= state.kawaseBlurRadius)
                {
                    id<MTLTexture> tempTexture = outputTexture;
                    outputTexture = inputTexture;
                    inputTexture = tempTexture;
                    
                    colorAttachmentDescriptor.texture = outputTexture;
                    renderPassDescriptor.colorAttachments [ 0 ] = colorAttachmentDescriptor;
                    commandEncoder  = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
                    
                    renderer.setEncoder(commandEncoder);
                    renderer.setViewport(viewport);
                    
                    renderer.setRenderPipelineState(pipelineState);
                    renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
                    renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
                    renderer.setFragmentTexture(inputTexture, TI_KawaseBlurInputImage);
                    renderer.setFragmentBytes(&texelSizeX, sizeof(texelSizeX), FIKB_TexelSizeX);
                    renderer.setFragmentBytes(&texelSizeY, sizeof(texelSizeY), FIKB_TexelSizeY);
                    renderer.setFragmentBytes(&tempRad, sizeof(tempRad), FIKB_BlurRadius);
                    renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
                    renderer.endEncoding();
                }
            }
            
            renderer.commitAndWaitUntilCompleted();
            break;
        }
            
#pragma mark -
#pragma mark Box Blur effect
        case (ET_BoxBlur):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_BoxBlur];

            renderer.setRenderPipelineState(pipelineState);
            renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
            renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
            renderer.setFragmentTexture(inputTexture, TI_BoxBlurInputImage);
            renderer.setFragmentBytes(&texelSizeX, sizeof(texelSizeX), FIGB_TexelSizeX);
            renderer.setFragmentBytes(&texelSizeY, sizeof(texelSizeY), FIGB_TexelSizeY);
            renderer.setFragmentBytes(&state.boxBlurRadius, sizeof(state.boxBlurRadius), FIBB_BlurRadius);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();
            break;
        }
            
#pragma mark -
#pragma mark Circle Blur effect
        case (ET_CircleBlur):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_CircleBlur];

            renderer.setRenderPipelineState(pipelineState);
            renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
            renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
            renderer.setFragmentTexture(inputTexture, TI_CircleBlurInputImage);
            renderer.setFragmentBytes(&texelSizeX, sizeof(texelSizeX), FICB_TexelSizeX);
            renderer.setFragmentBytes(&texelSizeY, sizeof(texelSizeY), FICB_TexelSizeY);
            renderer.setFragmentBytes(&state.circleBlurRadius, sizeof(state.circleBlurRadius), FICB_BlurRadius);
            renderer.setFragmentBytes(&state.circleBlurLocationX, sizeof(state.circleBlurLocationX), FICB_LocationX);
            renderer.setFragmentBytes(&state.circleBlurLocationY, sizeof(state.circleBlurLocationY), FICB_LocationY);
            renderer.setFragmentBytes(&state.circleBlurAmount, sizeof(state.circleBlurAmount), FICB_Amount);
            renderer.setFragmentBytes(&resolution, sizeof(resolution), FICB_Resolution);
            renderer.setFragmentBytes(&state.circleBlurMixFactor, sizeof(state.circleBlurMixFactor), FICB_Mix);
            renderer.setFragmentBytes(&state.circleBlurSmooth, sizeof(state.circleBlurSmooth), FICB_Smooth);
            
            if(!_mCache->contains(state.circleBlurAmount)) _mCache->putMatrixBuffer(state.circleBlurAmount);
                
            renderer.setFragmentBuffer(_mCache->get(state.circleBlurAmount), 0, FICB_Matrix);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();
            break;
            
        }
            
#pragma mark -
#pragma mark Oil painting effect
        case (ET_OilPainting):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_GaussianBlur];
            
            renderer.setRenderPipelineState(pipelineState);
            renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
            renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
            renderer.setFragmentTexture(inputTexture, TI_GaussianBlurInputImage);
            renderer.setFragmentBytes(&texelSizeX, sizeof(texelSizeX), FIGB_TexelSizeX);
            renderer.setFragmentBytes(&texelSizeY, sizeof(texelSizeY), FIGB_TexelSizeY);
            renderer.setFragmentBytes(&state.oilPaintingNoiseSuppression, sizeof(state.oilPaintingNoiseSuppression), FIGB_BlurRadius);

            if(!_mCache->contains(state.oilPaintingNoiseSuppression)) _mCache->putMatrixBuffer(state.oilPaintingNoiseSuppression);

            renderer.setFragmentBuffer(_mCache->get(state.oilPaintingNoiseSuppression), 0, FIGB_Matrix);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            
            id<MTLTexture> tempTexture = outputTexture;
            outputTexture = inputTexture;
            inputTexture = tempTexture;
            
            colorAttachmentDescriptor.texture = inputTexture;
            renderPassDescriptor.colorAttachments [ 0 ] = colorAttachmentDescriptor;
            commandEncoder  = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            
            pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_OilPainting];
            renderer.setEncoder(commandEncoder);
            renderer.setViewport(viewport);
            renderer.setRenderPipelineState(pipelineState);
            renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
            renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
            renderer.setFragmentTexture(inputTexture, TI_OilPaintingInputImage);
            renderer.setFragmentBytes(&texelSizeX, sizeof(texelSizeX), FIOP_TexelSizeX);
            renderer.setFragmentBytes(&texelSizeY, sizeof(texelSizeY), FIOP_TexelSizeY);
            renderer.setFragmentBytes(&state.oilPaintingRadius, sizeof(state.oilPaintingRadius), FIOP_Radius);
            renderer.setFragmentBytes(&state.oilPaintingLevelOfIntensity, sizeof(state.oilPaintingLevelOfIntensity), FIOP_LevelOfIntencity);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();
            break;
        }

#pragma mark -
#pragma mark Pixelation effect
        case(ET_Pixelization):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_Pixelation];
            renderer.setRenderPipelineState(pipelineState);
            renderer.setFragmentTexture(inputTexture, TI_PixelationInputImage);
            renderer.setFragmentBytes(&texelSizeX, sizeof(texelSizeX), FIP_TexelSizeX);
            renderer.setFragmentBytes(&texelSizeY, sizeof(texelSizeY), FIP_TexelSizeY);
            renderer.setFragmentBytes(&outputWidth, sizeof(outputWidth), FIP_Width);
            renderer.setFragmentBytes(&outputHeight, sizeof(outputHeight), FIP_Height);
            renderer.setFragmentBytes(&state.pixelationSize, sizeof(state.pixelationSize), FIP_Radius);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();
            break;
        }
            
#pragma mark -
#pragma mark Fish eye effect
        case(ET_FishEye):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_FishEye];
            renderer.setRenderPipelineState(pipelineState);
            renderer.setFragmentTexture(inputTexture, TI_FishEyeInputImage);
            renderer.setFragmentBytes(&state.fishEyeLocX, sizeof(state.fishEyeLocX), FIFE_LocationX);
            renderer.setFragmentBytes(&state.fishEyeLocY, sizeof(state.fishEyeLocY), FIFE_LocationY);
            renderer.setFragmentBytes(&state.fishEyeRad, sizeof(state.fishEyeRad), FIFE_Radius);
            renderer.setFragmentBytes(&state.fishEyeAmount, sizeof(state.fishEyeAmount), FIFE_Amount);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();
            break;
        }
            
#pragma mark -
#pragma mark Lens Flare pass
        case(ET_LensFlare):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_LensFlare];
            renderer.setRenderPipelineState(pipelineState);
            renderer.setFragmentTexture(inputTexture, TI_LensFlareInputImage);
            renderer.setFragmentBytes(&state.lensFlareSunColor, sizeof(state.lensFlareSunColor), FILF_SunColor);
            renderer.setFragmentBytes(&state.lensFlarePos, sizeof(state.lensFlarePos), FILF_Location);
            renderer.setFragmentBytes(&state.lensFlareShowImage, sizeof(state.lensFlareShowImage), FILF_ShowImage);
            renderer.setFragmentBytes(&state.lensFlareIntensityOfLight, sizeof(state.lensFlareIntensityOfLight), FILF_IntensityOfLight);
            renderer.setFragmentBytes(&state.lensFlareStrength, sizeof(state.lensFlareStrength), FILF_FlareStrength);
            renderer.setFragmentBytes(&state.lensFlareCheapFlare, sizeof(state.lensFlareCheapFlare), FILF_CheapFlare);
            renderer.setFragmentBytes(&state.lensFlareStretch, sizeof(state.lensFlareStretch), FILF_AnflareStretch);
            renderer.setFragmentBytes(&state.lensFlareBrightness, sizeof(state.lensFlareBrightness), FILF_AnflareBrightness);
            renderer.setFragmentBytes(&state.lensFlareThreshold, sizeof(state.lensFlareThreshold), FILF_AnflareThreshold);
            renderer.setFragmentBytes(&resolution, sizeof(resolution), FILF_Resolution);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();
            break;
        }
            
#pragma mark -
#pragma mark Echo effect
        case(ET_Echo):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_Echo];
            renderer.setRenderPipelineState(pipelineState);
            renderer.setFragmentTexture(inputTexture, TI_TimingEchoInputImage0);
            if(_typeToRenderEcho == TRT_Center)
            {
                for(int i=1; i<2*_numFrames-1; i++)
                {
                    id<MTLTexture> tex = [sourceImages[i] metalTextureForDevice:[deviceCache deviceWithRegistryID:sourceImages[i].deviceRegistryID]];
                    
                    TextureIndex idd = static_cast<TextureIndex>(TI_TimingEchoInputImage0 + i);
                    renderer.setFragmentTexture(tex, idd);
                }
            }
            if(_typeToRenderEcho == TRT_Back || _typeToRenderEcho == TRT_Front)
            {
                for(int i=1; i<_numFrames; i++)
                {
                    id<MTLTexture> tex = [sourceImages[i] metalTextureForDevice:[deviceCache deviceWithRegistryID:sourceImages[i].deviceRegistryID]];
                    
                    TextureIndex idd = static_cast<TextureIndex>(TI_TimingEchoInputImage0 + i);
                    renderer.setFragmentTexture(tex, idd);
                }
            }
            
            renderer.setFragmentBytes(&_numFrames, sizeof(_numFrames), FITE_TexturesAmount);
            renderer.setFragmentBytes(&_typeToRenderEcho, sizeof(_typeToRenderEcho), FITE_TimingRenderingType);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();
            break;
        }
            
            
#pragma mark -
#pragma mark Default pass
        default:
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_None];
            renderer.setRenderPipelineState(pipelineState);
            renderer.setFragmentTexture(inputTexture, TI_NoneInputImage);
            renderer.draw(MTLPrimitiveTypeTriangleStrip, 0, 4);
            renderer.endEncoding();
            renderer.commitAndWaitUntilCompleted();
            break;
        }
    }
    
//    commandBuffer = [commandQueue commandBuffer];
//    auto computeEncoder = [commandBuffer computeCommandEncoder];
//
//    auto pipState = [deviceCache computePipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
//                                                        pixelFormat:pixelFormat
//                                                       pipelineType:KPT_EdgeDetectionCalculateMagnitude];
//
//    [computeEncoder setComputePipelineState:pipState];
//    [computeEncoder setTexture:inputTexture atIndex:KTI_Magnidute];
//
//    id<MTLBuffer> maxMBuffer = [MTLCreateSystemDefaultDevice()
//                                newBufferWithLength:sizeof(float)
//                                options:MTLResourceStorageModeShared];
//
//    float maxM = 0.0;
//    memcpy(maxMBuffer.contents, &maxM, sizeof(int));
//    [computeEncoder setBuffer:maxMBuffer offset:0 atIndex:KI_Magnitude];
//
//    MTLSize threadgroupSize = MTLSizeMake(16, 16, 1);
//    MTLSize threadgroups = MTLSizeMake(inputTexture.width, inputTexture.height, 1);
//    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupSize];
//    [computeEncoder endEncoding];
//
//    [commandBuffer commit];
//    [commandBuffer waitUntilCompleted];
//
//    float maxVal = *(float*)[maxMBuffer contents];
//
//    NSLog(@"MAX %f", maxVal);
//
    
    [colorAttachmentDescriptor release];
    [deviceCache returnCommandQueueToCache:commandQueue];
    return YES;
}

@end
