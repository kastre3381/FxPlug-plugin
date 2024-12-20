#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>
#import <algorithm>
#import <cmath>
#import <concepts>
#import <map>
#import <vector>

/// Concept used for checing the type of buffer
template <typename T>
concept isBuffer = std::same_as<T, id<MTLBuffer>>;

/// Templated class used for caching the matrixes, in order to boost performace and speed of plugin
template <typename T> class MatrixCache {
public:
    MatrixCache() = default;
    MatrixCache(const MatrixCache &) = delete;
    MatrixCache(MatrixCache &&) = delete;
    MatrixCache &operator=(MatrixCache &&) = delete;
    MatrixCache &operator=(const MatrixCache &) = delete;

    bool contains(int key);
    void put(int key, T &buff) requires isBuffer<T>;
    T &get(int key);
    void putMatrixBuffer(int key) requires isBuffer<T>;

private:
    std::unordered_map<int, T> MatrixMap;
};





/// Method used for checking if map already contains the matrix for given key
template <typename T> bool MatrixCache<T>::contains(int key) {
    return MatrixMap.find(key) != MatrixMap.end();
}

/// Method used for putting matrix in map
template <typename T>
void MatrixCache<T>::put(int key, T &buff)
    requires isBuffer<T>
{
    MatrixMap[key] = buff;
}

/// Method used in getting matrix
template <typename T> T &MatrixCache<T>::get(int key) {
    return MatrixMap[key];
}

/// Method used for creating MTLBuffer for matrix of given radius
template <typename T>
void MatrixCache<T>::putMatrixBuffer(int key)
    requires isBuffer<T>
{
    auto vec = Matrix::getMatrixGaussian(key);
    id<MTLBuffer> buff = [MTLCreateSystemDefaultDevice() newBufferWithBytes:vec.data()
                                                                     length:vec.size() * sizeof(float)
                                                                    options:MTLResourceStorageModeShared];
    this->put(key, buff);
}
