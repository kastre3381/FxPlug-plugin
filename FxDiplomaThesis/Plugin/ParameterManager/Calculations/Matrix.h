#ifndef Matrix_h
#define Matrix_h

#import <Foundation/Foundation.h>
#import <cmath>
#import <vector>
#import <algorithm>
#import <iostream>
#import <simd/simd.h>

class Matrix {
private:
    static std::mutex myMutex;
    
public:
    
    static const std::vector<float> getMatrixGaussian(int radius)
    {
        
        float sigma = fmax(static_cast<float>(radius) / 2.0f, 1.0f);
        float sum = 0.0f;
        
        std::vector<float> vec((2*radius+1) * (2*radius+1));
        
        for(unsigned i{0}; i<2*radius+1; i++)
        {
            for(unsigned j{0}; j<2*radius+1; j++)
            {
                float xDist = (float)i - (float)radius;
                float yDist = (float)j - (float)radius;
                float exponent = -(xDist*xDist + yDist*yDist) / (2.0 * sigma * sigma);
                
                vec.at((2*radius+1) * i + j) = exp(exponent) / (2.0 * M_PI * sigma * sigma);
                sum += vec.at((2*radius+1) * i + j);
            }
        }
        
        
        for(unsigned i{0}; i<2*radius+1; i++)
        {
            for(unsigned j{0}; j<2*radius+1; j++)
            {
                vec.at((2*radius+1) * i + j) /= sum;
            }
        }
        
        sum = 0.0f;
        
        for(unsigned i{0}; i<2*radius+1; i++)
        {
            for(unsigned j{0}; j<2*radius+1; j++)
            {
                sum += vec.at((2*radius+1) * i + j);
            }
        }
 
        return vec;
    };
    
    
    
    static void convertFxMatrix44ToMatrixFloat44(FxMatrix44* fxMat, matrix_float4x4* floatMatrix)
    {
        Matrix44Data* mat = [fxMat matrix];
        for(int i=0; i<4; i++)
        {
            for (int j = 0; j < 4; j++)
            {
                floatMatrix->columns[j][i] = (*mat)[i][j];
            }
        }
    }
};


#endif /* Matrix_h */
