#import <FxPlug/FxPlugSDK.h>
#import "../ParameterFlags.h"
#import "../PluginState.h"

class ParameterManager
{
public:
    ParameterManager() = default;
    /// Method used in setting API for creating parameters
    void setParamApi(id<FxParameterCreationAPI_v5> api);
    /// Method used in setting API for changing flags of parameters
    void setSettingsApi(id<FxParameterSettingAPI_v6> api);
    /// Method used in setting API for retrieving values from parameters
    void setRetrievalApi(id<FxParameterRetrievalAPI_v6> api);
    /// Method used in setting API for setting values to parameters
    void setParamSetApi(id<FxParameterSettingAPI_v5> api);
    /// Method adding popup menu
    void addPopupMenu(NSString* name, ParameterFlags ID, int defVal, NSArray* entries, FxParameterFlags flag);
    /// Method adding float slider
    void addFloatSlider(NSString* name, ParameterFlags ID, double defVal, double parMin, double parMax, double sliderMin, double sliderMax, double delta, FxParameterFlags flag);
    /// Method adding int slider
    void addIntSlider(NSString* name, ParameterFlags ID, int defVal, int parMin, int parMax, int sliderMin, int sliderMax, int delta, FxParameterFlags flag);
    /// Method adding collor picked with alpha channel
    void addColorPickerWithAlpha(NSString* name, ParameterFlags ID, float defR, float defG, float defB, float defA, FxParameterFlags flag);
    /// Method adding color picker
    void addColorPicker(NSString* name, ParameterFlags ID, float defR, float defG, float defB, FxParameterFlags flag);
    /// Method adding percentage slider
    void addPercentSlider(NSString* name, ParameterFlags ID, double defVal, double parMin, double parMax, double sliderMin, double sliderMax, double delta, FxParameterFlags flag);
    /// Method adding toggle button
    void addToggleButton(NSString* name, ParameterFlags ID, bool defVal, FxParameterFlags flag);
    /// Method adding point parameter
    void addPointParameter(NSString* name, ParameterFlags ID, double defX, double defY, FxParameterFlags flag);
    /// Method adding angle slider
    void addAngleSlider(NSString* name, ParameterFlags ID, double defDeg, double minDeg, double maxDeg, FxParameterFlags flag);
    /// Method starting subgroup
    void startSubGroup(NSString* name, ParameterFlags ID, FxParameterFlags flag);
    /// Method adding push button
    void addPushButton(NSString* name, ParameterFlags ID, SEL sel, FxParameterFlags flag);
    /// Method ending subgroup
    void endSubGroup();
    /// Method hiding parameter
    void hide(ParameterFlags ID);
    /// Method showing parameter
    void show(ParameterFlags ID);
    /// Method disabling parameter
    void disable(ParameterFlags ID);
    /// Method setting point parameter values
    void setPointValues(float x, float y, ParameterFlags ID, CMTime time);
    /// Method getting integer value
    void getIntValue(int* val, ParameterFlags ID, CMTime time);
    /// Method getting flaoting point value
    void getFloatValue(float* val, ParameterFlags ID, CMTime time);
    /// Method getting color value with alpha channel
    void getColorValueWithAlpha(float* r, float* g, float* b, float* a, ParameterFlags ID, CMTime time);
    /// Method getting color value
    void getColorValue(float* r, float* g, float* b, ParameterFlags ID, CMTime time);
    /// Method getting boolean value
    void getBoolValue(BOOL* val, ParameterFlags ID, CMTime time);
    /// Method getting point parameter value (floating point)
    void getPointValues(float* x, float* y, ParameterFlags ID, CMTime time);
    /// Method getting point parameter value (double point)
    void getPointValues(double* x, double* y, ParameterFlags ID, CMTime time);
    /// Method increasing point (connected with ID) value by (x, y) vector
    void swapPointValues(double x, double y, ParameterFlags ID, CMTime time);
    /// Method increasing int (connected with ID) by x
    void swapIntValues(int x, ParameterFlags ID, CMTime time);
    /// Method increasing float (connected with ID) by x
    void swapFloatValues(double x, ParameterFlags ID, CMTime time);
    /// Method negating boolean values (connected with ID)
    void swapBoolValues(ParameterFlags ID, CMTime time);
private:
    id<FxParameterCreationAPI_v5> m_paramApi;
    id<FxParameterRetrievalAPI_v6> m_retrieveApi;
    id<FxParameterSettingAPI_v6> m_settingsApi;
    id<FxParameterSettingAPI_v5> m_setApi;
};
