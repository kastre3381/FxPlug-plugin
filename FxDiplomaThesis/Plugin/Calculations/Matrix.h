#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>
#import <algorithm>
#import <cmath>
#import <iostream>
#import <simd/simd.h>
#import <vector>


class Matrix {
public:
    /// Method used for calculating gaussian matrix for given radius
    static const std::vector<float> getMatrixGaussian(int radius);
    ///Method used for transorming FxMatrix44 to matrix_float4x4
    static void convertFxMatrix44ToMatrixFloat44(FxMatrix44 *fxMat, matrix_float4x4 *floatMatrix);
};
