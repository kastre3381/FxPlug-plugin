#ifndef MatrixCache_h
#define MatrixCache_h

#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>
#import <cmath>
#import <vector>
#import <algorithm>
#import <map>
#import <concepts>

template<typename T>
concept isBuffer = std::same_as<T, id<MTLBuffer>>;

template<typename T>
class MatrixCache {
    
    private:
        std::unordered_map<int, T> MatrixMap;

    public:
        MatrixCache() = default;
        MatrixCache(const MatrixCache&) = delete;
        MatrixCache(MatrixCache&&) = delete;
        MatrixCache& operator=(MatrixCache&&) = delete;
        MatrixCache& operator=(const MatrixCache&) = delete;
    
        bool contains(int key)
        {
            return MatrixMap.find(key) != MatrixMap.end();
        }
    
        void put(int key, T& buff) requires isBuffer<T>
        {
            MatrixMap[key] = buff;
        }
    
        T& get(int key)
        {
            return MatrixMap[key];
        }
        
        void putMatrixBuffer(int key) requires isBuffer<T>
        {
            auto vec = Matrix::getMatrixGaussian(key);
            id<MTLBuffer> buff = [MTLCreateSystemDefaultDevice()
                         newBufferWithBytes:vec.data()
                                   length:vec.size()*sizeof(float)
                         options:MTLResourceStorageModeShared];
            this->put(key, buff);
        }
};


#endif /* MatrixCache_h */
