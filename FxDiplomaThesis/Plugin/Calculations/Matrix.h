#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>
#import <algorithm>
#import <cmath>
#import <iostream>
#import <simd/simd.h>
#import <vector>


/// Class Matrix
class Matrix {
public:
    static const std::vector<float> getMatrixGaussian(int radius);
    static void convertFxMatrix44ToMatrixFloat44(FxMatrix44 *fxMat, matrix_float4x4 *floatMatrix);
};

/// Method used for calculating gaussian matrix for given radius
const std::vector<float> Matrix::getMatrixGaussian(int radius) {

    ///Initializing sigma and matrix
    float sigma = fmax(static_cast<float>(radius) / 2.0f, 1.0f);
    float sum = 0.0f;
    std::vector<float> vec((2 * radius + 1) * (2 * radius + 1));

    ///Calculating matrix values
    for (unsigned i{0}; i < 2 * radius + 1; i++) {
        for (unsigned j{0}; j < 2 * radius + 1; j++) {
            float xDist = (float)i - (float)radius;
            float yDist = (float)j - (float)radius;
            float exponent = -(xDist * xDist + yDist * yDist) / (2.0 * sigma * sigma);

            vec.at((2 * radius + 1) * i + j) = exp(exponent) / (2.0 * M_PI * sigma * sigma);
            sum += vec.at((2 * radius + 1) * i + j);
        }
    }

    /// Normalizing values
    for (unsigned i{0}; i < 2 * radius + 1; i++) {
        for (unsigned j{0}; j < 2 * radius + 1; j++) {
            vec.at((2 * radius + 1) * i + j) /= sum;
        }
    }

    return vec;
};


///Method used for transorming FxMatrix44 to matrix_float4x4
void Matrix::convertFxMatrix44ToMatrixFloat44(FxMatrix44 *fxMat, matrix_float4x4 *floatMatrix) {
    Matrix44Data *mat = [fxMat matrix];
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            floatMatrix->columns[j][i] = (*mat)[i][j];
        }
    }
}
