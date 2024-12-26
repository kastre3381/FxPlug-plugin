#import "ParameterManager.h"

void ParameterManager::setParamApi(id<FxParameterCreationAPI_v5> api) {
    m_paramApi = api;
}

void ParameterManager::setSettingsApi(id<FxParameterSettingAPI_v6> api) {
    m_settingsApi = api;
}

void ParameterManager::setRetrievalApi(id<FxParameterRetrievalAPI_v6> api) {
    m_retrieveApi = api;
}

void ParameterManager::setParamSetApi(id<FxParameterSettingAPI_v5> api) {
    m_setApi = api;
}

void ParameterManager::addPopupMenu(NSString *name, ParameterFlags ID, int defVal, NSArray *entries, FxParameterFlags flag) {
    [m_paramApi addPopupMenuWithName:name parameterID:ID defaultValue:defVal menuEntries:entries parameterFlags:flag];
}

void ParameterManager::addFloatSlider(NSString *name, ParameterFlags ID, double defVal, double parMin, double parMax, double sliderMin,
                                      double sliderMax, double delta, FxParameterFlags flag) {
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

void ParameterManager::addIntSlider(NSString *name, ParameterFlags ID, int defVal, int parMin, int parMax, int sliderMin, int sliderMax, int delta,
                                    FxParameterFlags flag) {
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

void ParameterManager::addColorPickerWithAlpha(NSString *name, ParameterFlags ID, float defR, float defG, float defB, float defA,
                                               FxParameterFlags flag) {
    [m_paramApi addColorParameterWithName:name
                              parameterID:ID
                               defaultRed:defR
                             defaultGreen:defG
                              defaultBlue:defB
                             defaultAlpha:defA
                           parameterFlags:flag];
}

void ParameterManager::addColorPicker(NSString *name, ParameterFlags ID, float defR, float defG, float defB, FxParameterFlags flag) {
    [m_paramApi addColorParameterWithName:name parameterID:ID defaultRed:defR defaultGreen:defG defaultBlue:defB parameterFlags:flag];
}

void ParameterManager::addPercentSlider(NSString *name, ParameterFlags ID, double defVal, double parMin, double parMax, double sliderMin,
                                        double sliderMax, double delta, FxParameterFlags flag) {
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

void ParameterManager::addToggleButton(NSString *name, ParameterFlags ID, bool defVal, FxParameterFlags flag) {
    [m_paramApi addToggleButtonWithName:name parameterID:ID defaultValue:defVal parameterFlags:flag];
}

void ParameterManager::addPointParameter(NSString *name, ParameterFlags ID, double defX, double defY, FxParameterFlags flag) {
    [m_paramApi addPointParameterWithName:name parameterID:ID defaultX:defX defaultY:defY parameterFlags:flag];
}

void ParameterManager::addAngleSlider(NSString *name, ParameterFlags ID, double defDeg, double minDeg, double maxDeg, FxParameterFlags flag) {
    [m_paramApi addAngleSliderWithName:name
                           parameterID:ID
                        defaultDegrees:defDeg
                   parameterMinDegrees:minDeg
                   parameterMaxDegrees:maxDeg
                        parameterFlags:flag];
}

void ParameterManager::startSubGroup(NSString *name, ParameterFlags ID, FxParameterFlags flag) {
    [m_paramApi startParameterSubGroup:name parameterID:ID parameterFlags:flag];
}

void ParameterManager::addPushButton(NSString *name, ParameterFlags ID, SEL sel, FxParameterFlags flag) {
    [m_paramApi addPushButtonWithName:name parameterID:ID selector:sel parameterFlags:flag];
}

void ParameterManager::endSubGroup() {
    [m_paramApi endParameterSubGroup];
}

void ParameterManager::hide(ParameterFlags ID) {
    [m_settingsApi setParameterFlags:kFxParameterFlag_HIDDEN toParameter:ID];
}

void ParameterManager::show(ParameterFlags ID) {
    [m_settingsApi setParameterFlags:kFxParameterFlag_DEFAULT toParameter:ID];
}

void ParameterManager::disable(ParameterFlags ID) {
    [m_settingsApi setParameterFlags:kFxParameterFlag_DISABLED toParameter:ID];
}

void ParameterManager::setPointValues(float x, float y, ParameterFlags ID, CMTime time) {
    [m_settingsApi setXValue:x YValue:y toParameter:ID atTime:time];
}

void ParameterManager::getIntValue(int *val, ParameterFlags ID, CMTime time) {
    [m_retrieveApi getIntValue:val fromParameter:ID atTime:time];
}

void ParameterManager::getFloatValue(float *val, ParameterFlags ID, CMTime time) {
    double temp;
    [m_retrieveApi getFloatValue:&temp fromParameter:ID atTime:time];

    *val = temp;
}

void ParameterManager::getColorValueWithAlpha(float *r, float *g, float *b, float *a, ParameterFlags ID, CMTime time) {
    double rr, bb, gg, aa;
    [m_retrieveApi getRedValue:&rr greenValue:&gg blueValue:&bb alphaValue:&aa fromParameter:ID atTime:time];
    *r = rr;
    *b = bb;
    *g = gg;
    *a = aa;
}

void ParameterManager::getColorValue(float *r, float *g, float *b, ParameterFlags ID, CMTime time) {
    double rr, bb, gg;
    [m_retrieveApi getRedValue:&rr greenValue:&gg blueValue:&bb fromParameter:ID atTime:time];
    *r = rr;
    *b = bb;
    *g = gg;
}

void ParameterManager::getBoolValue(BOOL *val, ParameterFlags ID, CMTime time) {
    [m_retrieveApi getBoolValue:val fromParameter:ID atTime:time];
}

void ParameterManager::getPointValues(float *x, float *y, ParameterFlags ID, CMTime time) {
    double x_temp;
    double y_temp;
    [m_retrieveApi getXValue:&x_temp YValue:&y_temp fromParameter:ID atTime:time];

    *x = x_temp;
    *y = y_temp;
}

void ParameterManager::getPointValues(double *x, double *y, ParameterFlags ID, CMTime time) {
    [m_retrieveApi getXValue:x YValue:y fromParameter:ID atTime:time];
}

void ParameterManager::swapPointValues(double x, double y, ParameterFlags ID, CMTime time) {
    CGPoint cc = {0.0, 0.0};
    [m_retrieveApi getXValue:&cc.x YValue:&cc.y fromParameter:ID atTime:time];
    cc.x += x;
    cc.y += y;
    [m_setApi setXValue:cc.x YValue:cc.y toParameter:ID atTime:time];
}

void ParameterManager::swapIntValues(int x, ParameterFlags ID, CMTime time) {
    int t = 0;
    [m_retrieveApi getIntValue:&t fromParameter:ID atTime:time];
    t += x;
    [m_setApi setIntValue:t toParameter:ID atTime:time];
}

void ParameterManager::swapFloatValues(double x, ParameterFlags ID, CMTime time) {
    double t = 0;
    [m_retrieveApi getFloatValue:&t fromParameter:ID atTime:time];
    t += x;
    [m_setApi setFloatValue:t toParameter:ID atTime:time];
}

void ParameterManager::swapBoolValues(ParameterFlags ID, CMTime time) {
    BOOL smooth = FALSE;
    [m_retrieveApi getBoolValue:&smooth fromParameter:ID atTime:time];
    smooth = !smooth;
    [m_setApi setBoolValue:smooth toParameter:ID atTime:time];
}
