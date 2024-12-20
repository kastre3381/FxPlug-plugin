#ifndef ParameterManager_h
#define ParameterManager_h

#import <FxPlug/FxPlugSDK.h>
#import "../ParameterFlags.h"
#import "../PluginState.h"

class ParameterManager
{
public:
    ParameterManager() = default;

    void setParamApi(id<FxParameterCreationAPI_v5> api)
    {
        m_paramApi = api;
    }
    
    void setSettingsApi(id<FxParameterSettingAPI_v6> api)
    {
        m_settingsApi = api;
    }
    
    void setRetrievalApi(id<FxParameterRetrievalAPI_v6> api)
    {
        m_retrieveApi = api;
    }
    
    void addPopupMenu(NSString* name, ParameterFlags ID, int defVal, NSArray* entries, FxParameterFlags flag)
    {
        [m_paramApi addPopupMenuWithName:name
                             parameterID:ID
                            defaultValue:defVal
                             menuEntries:entries
                          parameterFlags:flag];
    }
    
    void addFloatSlider(NSString* name, ParameterFlags ID, double defVal, double parMin, double parMax, double sliderMin, double sliderMax, double delta, FxParameterFlags flag)
    {
        [m_paramApi addFloatSliderWithName:name
                               parameterID:ID
                              defaultValue:defVal
                              parameterMin:parMin
                              parameterMax:parMax
                                 sliderMin:sliderMin
                                 sliderMax:sliderMax
                                     delta:delta
                            parameterFlags:flag];
    }
    
    void addIntSlider(NSString* name, ParameterFlags ID, int defVal, int parMin, int parMax, int sliderMin, int sliderMax, int delta, FxParameterFlags flag)
    {
        [m_paramApi addIntSliderWithName:name
                               parameterID:ID
                              defaultValue:defVal
                              parameterMin:parMin
                              parameterMax:parMax
                                 sliderMin:sliderMin
                                 sliderMax:sliderMax
                                     delta:delta
                            parameterFlags:flag];
    }
    
    void addColorPickerWithAlpha(NSString* name, ParameterFlags ID, float defR, float defG, float defB, float defA, FxParameterFlags flag)
    {
        [m_paramApi addColorParameterWithName:name
                                  parameterID:ID
                                   defaultRed:defR
                                 defaultGreen:defG
                                  defaultBlue:defB
                                 defaultAlpha:defA
                               parameterFlags:flag];
    }
    
    void addColorPicker(NSString* name, ParameterFlags ID, float defR, float defG, float defB, FxParameterFlags flag)
    {
        [m_paramApi addColorParameterWithName:name
                                  parameterID:ID
                                   defaultRed:defR
                                 defaultGreen:defG
                                  defaultBlue:defB
                               parameterFlags:flag];
    }
    
    void addPercentSlider(NSString* name, ParameterFlags ID, double defVal, double parMin, double parMax, double sliderMin, double sliderMax, double delta, FxParameterFlags flag)
    {
        [m_paramApi addPercentSliderWithName:name
                               parameterID:ID
                              defaultValue:defVal
                              parameterMin:parMin
                              parameterMax:parMax
                                 sliderMin:sliderMin
                                 sliderMax:sliderMax
                                     delta:delta
                            parameterFlags:flag];
    }
    
    void addToggleButton(NSString* name, ParameterFlags ID, bool defVal, FxParameterFlags flag)
    {
        [m_paramApi addToggleButtonWithName:name
                                parameterID:ID
                               defaultValue:defVal
                             parameterFlags:flag];
    }
    
    void addPointParameter(NSString* name, ParameterFlags ID, double defX, double defY, FxParameterFlags flag)
    {
        [m_paramApi addPointParameterWithName:name
                                  parameterID:ID
                                     defaultX:defX
                                     defaultY:defY
                               parameterFlags:flag];
    }
    
    void addAngleSlider(NSString* name, ParameterFlags ID, double defDeg, double minDeg, double maxDeg, FxParameterFlags flag)
    {
        [m_paramApi addAngleSliderWithName:name
                               parameterID:ID
                            defaultDegrees:defDeg
                       parameterMinDegrees:minDeg
                       parameterMaxDegrees:maxDeg
                            parameterFlags:flag];
    }
    
    void startSubGroup(NSString* name, ParameterFlags ID, FxParameterFlags flag)
    {
        [m_paramApi startParameterSubGroup:name
                               parameterID:ID
                            parameterFlags:flag];
    }
    
    void addPushButton(NSString* name, ParameterFlags ID, SEL sel, FxParameterFlags flag)
    {
        [m_paramApi addPushButtonWithName:name
                              parameterID:ID
                                 selector:sel
                           parameterFlags:flag];
    }
    
    void endSubGroup()
    {
        [m_paramApi endParameterSubGroup];
    }
    
    void hide(ParameterFlags ID)
    {
        [m_settingsApi setParameterFlags:kFxParameterFlag_HIDDEN
                             toParameter:ID];
    }
    
    void show(ParameterFlags ID)
    {
        [m_settingsApi setParameterFlags:kFxParameterFlag_DEFAULT
                             toParameter:ID];
    }
    
    void disable(ParameterFlags ID)
    {
        [m_settingsApi setParameterFlags:kFxParameterFlag_DISABLED
                             toParameter:ID];
    }
    
    void setPointValues(float x, float y, ParameterFlags ID, CMTime time)
    {
        [m_settingsApi setXValue:x
                          YValue:y
                     toParameter:ID
                          atTime:time];
    }
    
    void getIntValue(int* val, ParameterFlags ID, CMTime time)
    {
        [m_retrieveApi getIntValue:val
                     fromParameter:ID
                            atTime:time];
    }
    
    void getFloatValue(float* val, ParameterFlags ID, CMTime time)
    {
        double temp;
        [m_retrieveApi getFloatValue:&temp
                     fromParameter:ID
                            atTime:time];
        
        *val = temp;
    }
    
    void getColorValueWithAlpha(float* r, float* g, float* b, float* a, ParameterFlags ID, CMTime time)
    {
        double rr, bb, gg, aa;
        [m_retrieveApi getRedValue:&rr
                        greenValue:&gg
                         blueValue:&bb
                        alphaValue:&aa
                     fromParameter:ID
                            atTime:time];
        *r = rr;
        *b = bb;
        *g = gg;
        *a = aa;
    }
    
    void getColorValue(float* r, float* g, float* b, ParameterFlags ID, CMTime time)
    {
        double rr, bb, gg;
        [m_retrieveApi getRedValue:&rr
                        greenValue:&gg
                         blueValue:&bb
                     fromParameter:ID
                            atTime:time];
        *r = rr;
        *b = bb;
        *g = gg;
    }
    
    void getBoolValue(BOOL* val, ParameterFlags ID, CMTime time)
    {
        [m_retrieveApi getBoolValue:val
                     fromParameter:ID
                            atTime:time];
    }

    void getPointValues(float* x, float* y, ParameterFlags ID, CMTime time)
    {
        double x_temp;
        double y_temp;
        [m_retrieveApi getXValue:&x_temp
                          YValue:&y_temp
                   fromParameter:ID
                          atTime:time];
        
        *x = x_temp;
        *y = y_temp;
    }
    
    void getPointValues(double* x, double* y, ParameterFlags ID, CMTime time)
    {
        [m_retrieveApi getXValue:x
                          YValue:y
                   fromParameter:ID
                          atTime:time];
    }
    
private:
    id<FxParameterCreationAPI_v5> m_paramApi;
    id<FxParameterRetrievalAPI_v6> m_retrieveApi;
    id<FxParameterSettingAPI_v6> m_settingsApi;
};


#endif /* ParameterManager_h */
