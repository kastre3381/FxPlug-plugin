#include "OSC.h"

@implementation OSC {
    NSLock *lastPositionLock;
}

- (instancetype)initWithAPIManager:(id<PROAPIAccessing>)newAPIManager {
    self = [super init];

    if (self != nil) {
        _apiManager = newAPIManager;
        lastPositionLock = [[NSLock alloc] init];
        _size = NSMakeSize(0.0, 0.0);
        _smallRadius = 0.02;
        _unselectedColorCircleBlur = {0.01, 0.01, 0.01, 0.01};
        _selectedColorCircleBlur = {0.5, 0.5, 0.5, 0.5};
        _outlineColorCircleBlur = {1.0, 1.0, 1.0, 1.0};
        _colorFishEyeLensFlare = {1.0, 1.0, 1.0, 1.0};
        _outlineColorFishEyeLensFlare = {1.0, 0.0, 0.0, 1.0};
    }

    return self;
}

- (void)dealloc {
    [lastPositionLock release];
    [super dealloc];
}

- (void)canvasPoint:(CGPoint *)canvasPt
     forCircleCenter:(CGPoint)cc
               angle:(double)radians
    normalizedRadius:(CGPoint)normalizedRadius
          canvasSize:(NSSize)canvasSize
              oscAPI:(id<FxOnScreenControlAPI_v4>)oscAPI {
    CGPoint objectPt;
    objectPt.x = cc.x + cos(radians) * normalizedRadius.x;
    objectPt.y = cc.y + sin(radians) * normalizedRadius.y;

    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_OBJECT
                            fromX:objectPt.x
                            fromY:objectPt.y
                          toSpace:kFxDrawingCoordinates_CANVAS
                              toX:&canvasPt->x
                              toY:&canvasPt->y];

    canvasPt->y = canvasSize.height - canvasPt->y;
    canvasPt->x -= canvasSize.width / 2.0;
    canvasPt->y -= canvasSize.height / 2.0;
}

- (void)drawCircleWithImageSize:(NSSize)canvasSize
                       renderer:(Renderer &)renderer
                     activePart:(NSInteger)activePart
                     effectType:(EffectTypes)effectType
                         atTime:(CMTime)time {
    double destImageWidth = canvasSize.width;
    double destImageHeight = canvasSize.height;

    id<FxParameterRetrievalAPI_v6> paramAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    id<FxOnScreenControlAPI_v4> oscAPI = [_apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    NSRect imageBounds = [oscAPI inputBounds];
    _size = NSMakeSize(imageBounds.size.width, imageBounds.size.height);
    CGPoint cc = {0.0, 0.0};
    double radius = 0.0;

    if (effectType == ET_CircleBlur) {
        [paramAPI getXValue:&cc.x YValue:&cc.y fromParameter:PF_CircleBlurLocation atTime:time];

        [paramAPI getFloatValue:&radius fromParameter:PF_CircleBlurRadius atTime:time];

        CGPoint normalizedRadius;
        radius *= imageBounds.size.height;
        normalizedRadius.x = radius / imageBounds.size.width;
        normalizedRadius.y = radius / imageBounds.size.height;

        CGPoint canvasCC = {0.0, 0.0};
        [oscAPI convertPointFromSpace:kFxDrawingCoordinates_OBJECT
                                fromX:cc.x
                                fromY:cc.y
                              toSpace:kFxDrawingCoordinates_CANVAS
                                  toX:&canvasCC.x
                                  toY:&canvasCC.y];
        canvasCC.y = destImageHeight - canvasCC.y;
        canvasCC.x -= destImageWidth / 2.0;
        canvasCC.y -= destImageHeight / 2.0;

        const size_t kNumAngles = 360;
        const double kDegreesPerIteration = 360.0 / kNumAngles;
        const size_t kNumCircleVertices = 3 * kNumAngles;

        Vertex2D circleVertices[kNumCircleVertices];
        simd_float2 zeroZero = {0.0, 0.0};
        CGPoint canvasPt;
        for (int i = 0; i < kNumAngles; ++i) {
            circleVertices[i * 3 + 0].position.x = canvasCC.x;
            circleVertices[i * 3 + 0].position.y = canvasCC.y;
            circleVertices[i * 3 + 0].textureCoordinate = zeroZero;

            double radians = (double)(i * kDegreesPerIteration) * M_PI / 180.0;
            [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:normalizedRadius canvasSize:canvasSize oscAPI:oscAPI];
            circleVertices[i * 3 + 1].position.x = canvasPt.x;
            circleVertices[i * 3 + 1].position.y = canvasPt.y;
            circleVertices[i * 3 + 1].textureCoordinate = zeroZero;

            radians = (double)((i + 1) * kDegreesPerIteration) * M_PI / 180.0;
            [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:normalizedRadius canvasSize:canvasSize oscAPI:oscAPI];
            circleVertices[i * 3 + 2].position.x = canvasPt.x;
            circleVertices[i * 3 + 2].position.y = canvasPt.y;
            circleVertices[i * 3 + 2].textureCoordinate = zeroZero;
        }

        Vertex2D outlineVertices[kNumAngles + 1];
        for (int i = 0; i < kNumAngles; ++i) {
            outlineVertices[i] = circleVertices[i * 3 + 1];
        }
        outlineVertices[kNumAngles] = outlineVertices[0];

        simd_uint2 viewportSize = {(unsigned int)(destImageWidth), (unsigned int)(destImageHeight)};

        renderer.setVertexBytes(circleVertices, sizeof(circleVertices), VI_Vertices);
        renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);

        if (activePart == AP_Null) {
            renderer.setFragmentBytes(&_unselectedColorCircleBlur, sizeof(_unselectedColorCircleBlur), FIOSC_Color);
        } else {
            renderer.setFragmentBytes(&_selectedColorCircleBlur, sizeof(_selectedColorCircleBlur), FIOSC_Color);
        }

        renderer.draw(MTLPrimitiveTypeTriangle, 0, kNumCircleVertices);

        renderer.setVertexBytes(outlineVertices, sizeof(outlineVertices), VI_Vertices);
        renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
        renderer.setFragmentBytes(&_outlineColorCircleBlur, sizeof(_outlineColorCircleBlur), FIOSC_Color);
        renderer.draw(MTLPrimitiveTypeLineStrip, 0, kNumAngles + 1);
    }

    else if (effectType == ET_LensFlare || effectType == ET_FishEye) {
        if (effectType == ET_LensFlare) {
            [paramAPI getXValue:&cc.x YValue:&cc.y fromParameter:PF_LensFlareLocation atTime:time];
        }

        else {
            [paramAPI getXValue:&cc.x YValue:&cc.y fromParameter:PF_FishEyeLocation atTime:time];
        }

        radius = _smallRadius;
        double innerRadius = 2. / 3. * radius;
        double outerRadius = 4. / 3. * radius;
        double circleRadius = 1. / 3. * radius;

        CGPoint normalizedRadius;
        radius *= imageBounds.size.height;
        normalizedRadius.x = radius / imageBounds.size.width;
        normalizedRadius.y = radius / imageBounds.size.height;

        CGPoint normalizedInnerRadius;
        innerRadius *= imageBounds.size.height;
        normalizedInnerRadius.x = innerRadius / imageBounds.size.width;
        normalizedInnerRadius.y = innerRadius / imageBounds.size.height;

        CGPoint normalizedOuterRadius;
        outerRadius *= imageBounds.size.height;
        normalizedOuterRadius.x = outerRadius / imageBounds.size.width;
        normalizedOuterRadius.y = outerRadius / imageBounds.size.height;

        CGPoint normalizedCircleRadius;
        circleRadius *= imageBounds.size.height;
        normalizedCircleRadius.x = circleRadius / imageBounds.size.width;
        normalizedCircleRadius.y = circleRadius / imageBounds.size.height;

        CGPoint canvasCC = {0.0, 0.0};
        [oscAPI convertPointFromSpace:kFxDrawingCoordinates_OBJECT
                                fromX:cc.x
                                fromY:cc.y
                              toSpace:kFxDrawingCoordinates_CANVAS
                                  toX:&canvasCC.x
                                  toY:&canvasCC.y];
        canvasCC.y = destImageHeight - canvasCC.y;
        canvasCC.x -= destImageWidth / 2.0;
        canvasCC.y -= destImageHeight / 2.0;

        const size_t kNumAngles = 180;
        const double kDegreesPerIteration = 360.0 / kNumAngles;
        size_t kNumCircleVertices = (activePart == AP_Null ? 6 * kNumAngles : 3 * kNumAngles + 6 * kNumAngles * 2 / 3 - 6);

        Vertex2D pointVertices[kNumCircleVertices], outlineVerticesInner[kNumAngles + 1], outlineVerticesOuter[kNumAngles + 1], unselectedCircleVertices[kNumAngles + 1];

        CGPoint minRad, maxRad;
        if (activePart == AP_Null) {
            minRad = normalizedInnerRadius;
            maxRad = normalizedRadius;
        } else {
            minRad = normalizedRadius;
            maxRad = normalizedOuterRadius;
        }

        simd_float2 zeroZero = {0.0, 0.0};
        CGPoint canvasPt;
        int currIndex = 0;

        if (activePart == AP_Null) {
            for (int i = 0; i < kNumAngles; i++) {
                /// Outer circle unselected
                {
                    double radians = (double)(i * kDegreesPerIteration) * M_PI / 180.0;
                    [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:minRad canvasSize:canvasSize oscAPI:oscAPI];
                    pointVertices[6 * i + 0].position.x = canvasPt.x;
                    pointVertices[6 * i + 0].position.y = canvasPt.y;
                    pointVertices[6 * i + 0].textureCoordinate = zeroZero;

                    outlineVerticesInner[i].position.x = canvasPt.x;
                    outlineVerticesInner[i].position.y = canvasPt.y;
                    outlineVerticesInner[i].textureCoordinate = zeroZero;

                    radians = (double)(i * kDegreesPerIteration) * M_PI / 180.0;
                    [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:maxRad canvasSize:canvasSize oscAPI:oscAPI];
                    pointVertices[6 * i + 1].position.x = canvasPt.x;
                    pointVertices[6 * i + 1].position.y = canvasPt.y;
                    pointVertices[6 * i + 1].textureCoordinate = zeroZero;

                    outlineVerticesOuter[i].position.x = canvasPt.x;
                    outlineVerticesOuter[i].position.y = canvasPt.y;
                    outlineVerticesOuter[i].textureCoordinate = zeroZero;

                    radians = (double)((i + 1) * kDegreesPerIteration) * M_PI / 180.0;
                    [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:maxRad canvasSize:canvasSize oscAPI:oscAPI];
                    pointVertices[6 * i + 2].position.x = canvasPt.x;
                    pointVertices[6 * i + 2].position.y = canvasPt.y;
                    pointVertices[6 * i + 2].textureCoordinate = zeroZero;

                    pointVertices[6 * i + 3].position.x = pointVertices[6 * i + 0].position.x;
                    pointVertices[6 * i + 3].position.y = pointVertices[6 * i + 0].position.y;
                    pointVertices[6 * i + 3].textureCoordinate = pointVertices[6 * i + 0].textureCoordinate;

                    pointVertices[6 * i + 4].position.x = pointVertices[6 * i + 2].position.x;
                    pointVertices[6 * i + 4].position.y = pointVertices[6 * i + 2].position.y;
                    pointVertices[6 * i + 4].textureCoordinate = pointVertices[6 * i + 2].textureCoordinate;

                    radians = (double)((i + 1) * kDegreesPerIteration) * M_PI / 180.0;
                    [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:minRad canvasSize:canvasSize oscAPI:oscAPI];
                    pointVertices[6 * i + 5].position.x = canvasPt.x;
                    pointVertices[6 * i + 5].position.y = canvasPt.y;
                    pointVertices[6 * i + 5].textureCoordinate = zeroZero;
                }
            }

            outlineVerticesInner[kNumAngles] = outlineVerticesInner[0];
            outlineVerticesOuter[kNumAngles] = outlineVerticesOuter[0];
        } else {
            for (int i = 0; i < kNumAngles; i++) {
                ////// Circle in the middle
                {
                    pointVertices[currIndex].position.x = canvasCC.x;
                    pointVertices[currIndex].position.y = canvasCC.y;
                    pointVertices[currIndex].textureCoordinate = zeroZero;
                    currIndex++;

                    double radians = (double)(i * kDegreesPerIteration) * M_PI / 180.0;
                    [self canvasPoint:&canvasPt
                         forCircleCenter:cc
                                   angle:radians
                        normalizedRadius:normalizedCircleRadius
                              canvasSize:canvasSize
                                  oscAPI:oscAPI];
                    pointVertices[currIndex].position.x = canvasPt.x;
                    pointVertices[currIndex].position.y = canvasPt.y;
                    pointVertices[currIndex].textureCoordinate = zeroZero;
                    unselectedCircleVertices[i] = pointVertices[currIndex];
                    currIndex++;

                    radians = (double)((i + 1) * kDegreesPerIteration) * M_PI / 180.0;
                    [self canvasPoint:&canvasPt
                         forCircleCenter:cc
                                   angle:radians
                        normalizedRadius:normalizedCircleRadius
                              canvasSize:canvasSize
                                  oscAPI:oscAPI];
                    pointVertices[currIndex].position.x = canvasPt.x;
                    pointVertices[currIndex].position.y = canvasPt.y;
                    pointVertices[currIndex].textureCoordinate = zeroZero;
                    currIndex++;
                }

                /// Outer circle unselected
                {
                    double radiansLeft = (double)(i * kDegreesPerIteration) * M_PI / 180.0;
                    double radiansRight = (double)((i + 1) * kDegreesPerIteration) * M_PI / 180.0;

                    if ((radiansLeft >= M_PI / 3.0 && radiansRight >= M_PI / 3.0 && radiansLeft <= 2.0 * M_PI / 3.0 &&
                         radiansRight <= 2.0 * M_PI / 3.0) ||
                        (radiansLeft >= 5.0 * M_PI / 6.0 && radiansRight >= 5.0 * M_PI / 6.0 && radiansLeft <= 7.0 * M_PI / 6.0 &&
                         radiansRight <= 7.0 * M_PI / 6.0) ||
                        (radiansLeft >= 4.0 * M_PI / 3.0 && radiansRight >= 4.0 * M_PI / 3.0 && radiansLeft <= 5.0 * M_PI / 3.0 &&
                         radiansRight <= 5.0 * M_PI / 3.0) ||
                        (radiansLeft >= 0.0 && radiansRight >= 0.0 && radiansLeft <= M_PI / 6.0 && radiansRight <= M_PI / 6.0) ||
                        (radiansLeft >= 11.0 * M_PI / 6.0 && radiansRight >= 11.0 * M_PI / 6.0 && radiansLeft <= 2.0 * M_PI &&
                         radiansRight <= 2.0 * M_PI)) {
                        double radians = (double)(i * kDegreesPerIteration) * M_PI / 180.0;
                        [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:minRad canvasSize:canvasSize oscAPI:oscAPI];
                        pointVertices[currIndex].position.x = canvasPt.x;
                        pointVertices[currIndex].position.y = canvasPt.y;
                        pointVertices[currIndex].textureCoordinate = zeroZero;

                        

                        currIndex++;

                        radians = (double)(i * kDegreesPerIteration) * M_PI / 180.0;
                        [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:maxRad canvasSize:canvasSize oscAPI:oscAPI];
                        pointVertices[currIndex].position.x = canvasPt.x;
                        pointVertices[currIndex].position.y = canvasPt.y;
                        pointVertices[currIndex].textureCoordinate = zeroZero;

                        
                        currIndex++;

                        radians = (double)((i + 1) * kDegreesPerIteration) * M_PI / 180.0;
                        [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:maxRad canvasSize:canvasSize oscAPI:oscAPI];
                        pointVertices[currIndex].position.x = canvasPt.x;
                        pointVertices[currIndex].position.y = canvasPt.y;
                        pointVertices[currIndex].textureCoordinate = zeroZero;
                        currIndex++;

                        pointVertices[currIndex].position.x = pointVertices[currIndex - 3].position.x;
                        pointVertices[currIndex].position.y = pointVertices[currIndex - 3].position.y;
                        pointVertices[currIndex].textureCoordinate = pointVertices[currIndex - 3].textureCoordinate;
                        currIndex++;

                        pointVertices[currIndex].position.x = pointVertices[currIndex - 2].position.x;
                        pointVertices[currIndex].position.y = pointVertices[currIndex - 2].position.y;
                        pointVertices[currIndex].textureCoordinate = pointVertices[currIndex - 2].textureCoordinate;
                        currIndex++;

                        radians = (double)((i + 1) * kDegreesPerIteration) * M_PI / 180.0;
                        [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:minRad canvasSize:canvasSize oscAPI:oscAPI];
                        pointVertices[currIndex].position.x = canvasPt.x;
                        pointVertices[currIndex].position.y = canvasPt.y;
                        pointVertices[currIndex].textureCoordinate = zeroZero;
                        currIndex++;
                    }
                }
            }
            kNumCircleVertices = currIndex;

            unselectedCircleVertices[kNumAngles] = unselectedCircleVertices[0];
        }

        simd_uint2 viewportSize = {(unsigned int)(destImageWidth), (unsigned int)(destImageHeight)};

        renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
        renderer.setFragmentBytes(&_colorFishEyeLensFlare, sizeof(_colorFishEyeLensFlare), FIOSC_Color);


        if (activePart == AP_Null) {
            renderer.setVertexBytes(pointVertices, sizeof(pointVertices), VI_Vertices);
        } else {
            renderer.setVertexBytes(pointVertices, sizeof(pointVertices), VI_Vertices);
        }

        renderer.draw(MTLPrimitiveTypeTriangle, 0, kNumCircleVertices);

        if (activePart == AP_Null) {
            renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
            renderer.setFragmentBytes(&_outlineColorFishEyeLensFlare, sizeof(_outlineColorFishEyeLensFlare), FIOSC_Color);
            renderer.setVertexBytes(outlineVerticesInner, sizeof(outlineVerticesInner), VI_Vertices);
            renderer.draw(MTLPrimitiveTypeLineStrip, 0, kNumAngles + 1);

            renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
            renderer.setFragmentBytes(&_outlineColorFishEyeLensFlare, sizeof(_outlineColorFishEyeLensFlare), FIOSC_Color);
            renderer.setVertexBytes(outlineVerticesOuter, sizeof(outlineVerticesOuter), VI_Vertices);
            renderer.draw(MTLPrimitiveTypeLineStrip, 0, kNumAngles + 1);
        } else if (activePart == AP_FishEye || activePart == AP_LensFlare) {
            renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
            renderer.setFragmentBytes(&_outlineColorFishEyeLensFlare, sizeof(_outlineColorFishEyeLensFlare), FIOSC_Color);
            renderer.setVertexBytes(unselectedCircleVertices, sizeof(unselectedCircleVertices), VI_Vertices);
            renderer.draw(MTLPrimitiveTypeLineStrip, 0, kNumAngles + 1);
        }
    }
}

- (CGPoint)getPointInCanvas:(CGPoint)cc
                     oscApi:(id<FxOnScreenControlAPI_v4>)oscAPI
             destImageWidth:(double)destImageWidth
            destImageHeight:(double)destImageHeight {
    CGPoint canvasCC = {0.0, 0.0};
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_OBJECT
                            fromX:cc.x
                            fromY:cc.y
                          toSpace:kFxDrawingCoordinates_CANVAS
                              toX:&canvasCC.x
                              toY:&canvasCC.y];
    canvasCC.y = destImageHeight - canvasCC.y;
    canvasCC.x -= destImageWidth / 2.0;
    canvasCC.y -= destImageHeight / 2.0;
    return canvasCC;
}

- (void)drawCircle:(ParameterFlags)centerFlag
           renderer:(Renderer &)renderer
     destImageWidth:(double)destImageWidth
    destImageHeight:(double)destImageHeight
        imageBounds:(NSRect)imageBounds
             oscApi:(id<FxOnScreenControlAPI_v4>)oscAPI
           paramAPI:(id<FxParameterRetrievalAPI_v6>)paramAPI
         canvasSize:(NSSize)canvasSize
             active:(BOOL)active
       viewportSize:(simd_uint2)viewportSize
               time:(CMTime)time {
    CGPoint cc = {0.0, 0.0};

    [paramAPI getXValue:&cc.x YValue:&cc.y fromParameter:centerFlag atTime:time];

    CGPoint normalizedRadius;
    double radius = _smallRadius;
    radius *= imageBounds.size.height;
    normalizedRadius.x = radius / imageBounds.size.width;
    normalizedRadius.y = radius / imageBounds.size.height;

    CGPoint canvasCC = {0.0, 0.0};
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_OBJECT
                            fromX:cc.x
                            fromY:cc.y
                          toSpace:kFxDrawingCoordinates_CANVAS
                              toX:&canvasCC.x
                              toY:&canvasCC.y];
    canvasCC.y = destImageHeight - canvasCC.y;
    canvasCC.x -= destImageWidth / 2.0;
    canvasCC.y -= destImageHeight / 2.0;

    const size_t kNumAngles = 360;
    const double kDegreesPerIteration = 360.0 / kNumAngles;
    const size_t kNumCircleVertices = 3 * kNumAngles;

    Vertex2D circleVertices[kNumCircleVertices];
    simd_float2 zeroZero = {0.0, 0.0};
    CGPoint canvasPt;
    for (int i = 0; i < kNumAngles; ++i) {
        circleVertices[i * 3 + 0].position.x = canvasCC.x;
        circleVertices[i * 3 + 0].position.y = canvasCC.y;
        circleVertices[i * 3 + 0].textureCoordinate = zeroZero;

        double radians = (double)(i * kDegreesPerIteration) * M_PI / 180.0;
        [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:normalizedRadius canvasSize:canvasSize oscAPI:oscAPI];
        circleVertices[i * 3 + 1].position.x = canvasPt.x;
        circleVertices[i * 3 + 1].position.y = canvasPt.y;
        circleVertices[i * 3 + 1].textureCoordinate = zeroZero;

        radians = (double)((i + 1) * kDegreesPerIteration) * M_PI / 180.0;
        [self canvasPoint:&canvasPt forCircleCenter:cc angle:radians normalizedRadius:normalizedRadius canvasSize:canvasSize oscAPI:oscAPI];
        circleVertices[i * 3 + 2].position.x = canvasPt.x;
        circleVertices[i * 3 + 2].position.y = canvasPt.y;
        circleVertices[i * 3 + 2].textureCoordinate = zeroZero;
    }

    Vertex2D outlineVertices[kNumAngles + 1];
    for (int i = 0; i < kNumAngles; ++i) {
        outlineVertices[i] = circleVertices[i * 3 + 1];
    }
    outlineVertices[kNumAngles] = outlineVertices[0];

    renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
    renderer.setVertexBytes(circleVertices, sizeof(circleVertices), VI_Vertices);

    if (active) {
        renderer.setFragmentBytes(&_selectedColorCircleBlur, sizeof(_selectedColorCircleBlur), FIOSC_Color);
    } else {
        renderer.setFragmentBytes(&_unselectedColorCircleBlur, sizeof(_unselectedColorCircleBlur), FIOSC_Color);
    }
    renderer.draw(MTLPrimitiveTypeTriangle, 0, kNumCircleVertices);

    renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
    renderer.setVertexBytes(outlineVertices, sizeof(outlineVertices), VI_Vertices);
    renderer.setFragmentBytes(&_outlineColorCircleBlur, sizeof(_outlineColorCircleBlur), FIOSC_Color);
    renderer.draw(MTLPrimitiveTypeLineStrip, 0, kNumAngles);
}

- (void)drawPolygonCircles:(ParameterFlags)centerFlag
                  renderer:(Renderer &)renderer
            destImageWidth:(double)destImageWidth
           destImageHeight:(double)destImageHeight
               imageBounds:(NSRect)imageBounds
                    oscApi:(id<FxOnScreenControlAPI_v4>)oscAPI
                  paramAPI:(id<FxParameterRetrievalAPI_v6>)paramAPI
                canvasSize:(NSSize)canvasSize
              viewportSize:(simd_uint2)viewportSize
                      time:(CMTime)time
                activePart:(NSInteger)activePart {
    int num = 0;
    [paramAPI getIntValue:&num fromParameter:PF_BasicOSCMenu atTime:time];

    if (num >= 1) {
        if (activePart == AP_Basic1)
            [self drawCircle:PF_BasicPosition1
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition1
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 1) {
        if (activePart == AP_Basic2)
            [self drawCircle:PF_BasicPosition2
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition2
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 1) {
        if (activePart == AP_Basic3)
            [self drawCircle:PF_BasicPosition3
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition3
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 2) {
        if (activePart == AP_Basic4)
            [self drawCircle:PF_BasicPosition4
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition4
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 3) {
        if (activePart == AP_Basic5)
            [self drawCircle:PF_BasicPosition5
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition5
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 4) {
        if (activePart == AP_Basic6)
            [self drawCircle:PF_BasicPosition6
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition6
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 5) {
        if (activePart == AP_Basic7)
            [self drawCircle:PF_BasicPosition7
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition7
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 6) {
        if (activePart == AP_Basic8)
            [self drawCircle:PF_BasicPosition8
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition8
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 7) {
        if (activePart == AP_Basic9)
            [self drawCircle:PF_BasicPosition9
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition9
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 8) {
        if (activePart == AP_Basic10)
            [self drawCircle:PF_BasicPosition10
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition10
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 9) {
        if (activePart == AP_Basic11)
            [self drawCircle:PF_BasicPosition11
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition11
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }

    if (num >= 10) {
        if (activePart == AP_Basic12)
            [self drawCircle:PF_BasicPosition12
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:TRUE
                   viewportSize:viewportSize
                           time:time];
        else
            [self drawCircle:PF_BasicPosition12
                       renderer:renderer
                 destImageWidth:destImageWidth
                destImageHeight:destImageHeight
                    imageBounds:imageBounds
                         oscApi:oscAPI
                       paramAPI:paramAPI
                     canvasSize:canvasSize
                         active:FALSE
                   viewportSize:viewportSize
                           time:time];
    }
}

- (void)drawPolygonWithImageSize:(NSSize)canvasSize renderer:(Renderer &)renderer activePart:(NSInteger)activePart atTime:(CMTime)time {
    double destImageWidth = canvasSize.width;
    double destImageHeight = canvasSize.height;

    std::cout << "Width " << destImageWidth << ", height " << destImageHeight << std::endl;

    id<FxParameterRetrievalAPI_v6> paramAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    id<FxOnScreenControlAPI_v4> oscAPI = [_apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    NSRect imageBounds = [oscAPI inputBounds];
    _size = NSMakeSize(imageBounds.size.width, imageBounds.size.height);

    int vertices = 0;
    [paramAPI getIntValue:&vertices fromParameter:PF_BasicOSCMenu atTime:time];
    if (vertices == 0)
        return;
    else
        vertices += 2;

    simd_float2 zeroZero = {0.0, 0.0};

    Vertex2D outlineVertices[vertices + 1];
    for (int i = 0; i < vertices; ++i) {
        CGPoint pos = {0.0, 0.0};
        [paramAPI getXValue:&pos.x YValue:&pos.y fromParameter:PF_BasicPosition1 + i atTime:time];
        auto normalizedPos = [self getPointInCanvas:pos oscApi:oscAPI destImageWidth:destImageWidth destImageHeight:destImageHeight];
        outlineVertices[i].position.x = normalizedPos.x;
        outlineVertices[i].position.y = normalizedPos.y;
        outlineVertices[i].textureCoordinate = zeroZero;
    }
    outlineVertices[vertices] = outlineVertices[0];

    simd_uint2 viewportSize = {(unsigned int)(destImageWidth), (unsigned int)(destImageHeight)};

    std::vector<CGPoint> positions;

    int numVertices;
    [paramAPI getIntValue:&numVertices fromParameter:PF_BasicOSCMenu atTime:time];

    if (numVertices > 0) {
        numVertices += 2;
        CGPoint pos1, pos2, pos3;
        [paramAPI getXValue:&pos1.x YValue:&pos1.y fromParameter:PF_BasicPosition1 atTime:time];
        [paramAPI getXValue:&pos2.x YValue:&pos2.y fromParameter:PF_BasicPosition2 atTime:time];
        [paramAPI getXValue:&pos3.x YValue:&pos3.y fromParameter:PF_BasicPosition3 atTime:time];

        positions.push_back(pos1);
        positions.push_back(pos2);
        positions.push_back(pos3);

        if (numVertices >= 4) {
            CGPoint pt;
            [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:PF_BasicPosition4 atTime:time];
            positions.push_back(pt);
        }
        if (numVertices >= 5) {
            CGPoint pt;
            [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:PF_BasicPosition5 atTime:time];
            positions.push_back(pt);
        }
        if (numVertices >= 6) {
            CGPoint pt;
            [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:PF_BasicPosition6 atTime:time];
            positions.push_back(pt);
        }
        if (numVertices >= 7) {
            CGPoint pt;
            [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:PF_BasicPosition7 atTime:time];
            positions.push_back(pt);
        }
        if (numVertices >= 8) {
            CGPoint pt;
            [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:PF_BasicPosition8 atTime:time];
            positions.push_back(pt);
        }
        if (numVertices >= 9) {
            CGPoint pt;
            [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:PF_BasicPosition9 atTime:time];
            positions.push_back(pt);
        }
        if (numVertices >= 10) {
            CGPoint pt;
            [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:PF_BasicPosition10 atTime:time];
            positions.push_back(pt);
        }
        if (numVertices >= 11) {
            CGPoint pt;
            [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:PF_BasicPosition11 atTime:time];
            positions.push_back(pt);
        }
        if (numVertices >= 12) {
            CGPoint pt;
            [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:PF_BasicPosition12 atTime:time];
            positions.push_back(pt);
        }

        auto triangles = Triangulation::getTriangulation(positions);

        Vertex2D vertices[triangles.size()];

        for (int i = 0; i < triangles.size(); i++) {
            triangles[i] = [self getPointInCanvas:triangles[i] oscApi:oscAPI destImageWidth:destImageWidth destImageHeight:destImageHeight];
            vertices[i].position.x = triangles[i].x;
            vertices[i].position.y = triangles[i].y;
            vertices[i].textureCoordinate = zeroZero;
        }

        renderer.setVertexBytes(vertices, sizeof(vertices), VI_Vertices);
        renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
        if (activePart == AP_BasicOSC)
            renderer.setFragmentBytes(&_selectedColorCircleBlur, sizeof(_selectedColorCircleBlur), FIOSC_Color);
        else
            renderer.setFragmentBytes(&_unselectedColorCircleBlur, sizeof(_unselectedColorCircleBlur), FIOSC_Color);
        renderer.draw(MTLPrimitiveTypeTriangle, 0, triangles.size());
    }

    renderer.setVertexBytes(outlineVertices, sizeof(outlineVertices), VI_Vertices);
    renderer.setVertexBytes(&viewportSize, sizeof(viewportSize), VI_ViewportSize);
    renderer.setFragmentBytes(&_outlineColorCircleBlur, sizeof(_outlineColorCircleBlur), FIOSC_Color);
    renderer.draw(MTLPrimitiveTypeLineStrip, 0, vertices + 1);

    [self drawPolygonCircles:PF_BasicPosition1
                    renderer:renderer
              destImageWidth:destImageWidth
             destImageHeight:destImageHeight
                 imageBounds:imageBounds
                      oscApi:oscAPI
                    paramAPI:paramAPI
                  canvasSize:canvasSize
                viewportSize:viewportSize
                        time:time
                  activePart:activePart];
}

- (void)drawOSC:(FxImageTile *)destinationImage renderer:(Renderer &)renderer activePart:(NSInteger)activePart atTime:(CMTime)time {
    float destImageWidth = destinationImage.imagePixelBounds.right - destinationImage.imagePixelBounds.left;
    float destImageHeight = destinationImage.imagePixelBounds.top - destinationImage.imagePixelBounds.bottom;

    float ioSurfaceHeight = [destinationImage.ioSurface height];
    MTLViewport viewport = {0, ioSurfaceHeight - destImageHeight, destImageWidth, destImageHeight, -1.0, 1.0};
    renderer.setViewport(viewport);

    id<FxParameterRetrievalAPI_v6> paramAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    int et;

    [paramAPI getIntValue:&et fromParameter:PF_EffectTypes atTime:time];

    if (et == ET_Blur) {
        [self drawCircleWithImageSize:NSMakeSize(destImageWidth, destImageHeight)
                             renderer:renderer
                           activePart:activePart
                           effectType:ET_CircleBlur
                               atTime:time];
    }

    else if (et == ET_SpecialEffect) {
        [self drawCircleWithImageSize:NSMakeSize(destImageWidth, destImageHeight)
                             renderer:renderer
                           activePart:activePart
                           effectType:ET_FishEye
                               atTime:time];
    }

    else if (et == ET_LensFlare) {
        [self drawCircleWithImageSize:NSMakeSize(destImageWidth, destImageHeight)
                             renderer:renderer
                           activePart:activePart
                           effectType:ET_LensFlare
                               atTime:time];
    }

    else if (et == ET_Basic) {
        [self drawPolygonWithImageSize:NSMakeSize(destImageWidth, destImageHeight) renderer:renderer activePart:activePart atTime:time];
    }
}

- (void)drawOSCWithWidth:(NSInteger)width
                  height:(NSInteger)height
              activePart:(NSInteger)activePart
        destinationImage:(FxImageTile *)destinationImage
                  atTime:(CMTime)time {
    MetalDeviceCache *deviceCache = [MetalDeviceCache deviceCache];
    id<MTLDevice> gpuDevice = [deviceCache deviceWithRegistryID:destinationImage.deviceRegistryID];
    id<MTLCommandQueue> commandQueue = [deviceCache commandQueueWithRegistryID:destinationImage.deviceRegistryID
                                                                   pixelFormat:MTLPixelFormatRGBA16Float];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    [commandBuffer enqueue];

    id<MTLTexture> outputTexture = [destinationImage metalTextureForDevice:gpuDevice];
    MTLRenderPassColorAttachmentDescriptor *colorAttachmentDescriptor = [[MTLRenderPassColorAttachmentDescriptor alloc] init];
    colorAttachmentDescriptor.texture = outputTexture;
    colorAttachmentDescriptor.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    colorAttachmentDescriptor.loadAction = MTLLoadActionClear;

    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0] = colorAttachmentDescriptor;

    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    id<MTLRenderPipelineState> pipelineState = [deviceCache oscPipelineStateWithRegistryID:destinationImage.deviceRegistryID];
    Renderer renderer(commandEncoder, commandBuffer);
    renderer.setRenderPipelineState(pipelineState);

    [self drawOSC:destinationImage renderer:renderer activePart:activePart atTime:time];

    renderer.endEncoding();
    renderer.commitAndWaitUntilCompleted();

    [deviceCache returnCommandQueueToCache:commandQueue];

    [colorAttachmentDescriptor release];
}

- (FxDrawingCoordinates)drawingCoordinates {
    return kFxDrawingCoordinates_CANVAS;
}

- (BOOL)checkCircleHitTest:(NSInteger *)activePart
              circleRadius:(double)circleRadius
                    oscAPI:(id<FxOnScreenControlAPI_v4>)oscAPI
              parameterAPI:(id<FxParameterRetrievalAPI_v6>)paramAPI
            objectPosition:(CGPoint)objectPosition
                      flag:(ParameterFlags)flag
                      time:(CMTime)time {
    CGPoint cc = {0.0, 0.0};
    [paramAPI getXValue:&cc.x YValue:&cc.y fromParameter:flag atTime:time];

    circleRadius *= _size.height;

    *activePart = AP_Null;
    NSRect inputBounds = [oscAPI inputBounds];
    double objectRadius = circleRadius / inputBounds.size.width;

    CGPoint delta = {objectPosition.x - cc.x, (objectPosition.y - cc.y) * inputBounds.size.height / inputBounds.size.width};

    double dist = sqrt(delta.x * delta.x + delta.y * delta.y);

    if (dist < objectRadius)
        return TRUE;

    return FALSE;
}

- (BOOL)checkPolygonHitTest:(CGPoint)objectPosition paramAPI:(id<FxParameterRetrievalAPI_v6>)paramAPI atTime:(CMTime)time {
    int vertices;
    [paramAPI getIntValue:&vertices fromParameter:PF_BasicOSCMenu atTime:time];

    if (vertices == 0)
        return FALSE;
    vertices += 2;

    std::vector<CGPoint> pointVector;

    for (int i = 0; i < vertices + 1; i++) {
        CGPoint pt;
        [paramAPI getXValue:&pt.x YValue:&pt.y fromParameter:(PF_BasicPosition1 + i % vertices) atTime:time];

        pointVector.push_back(pt);
    }
    int counter = 0;

    for (int i = 0; i < vertices; i++) {
        if ((pointVector[i].y > objectPosition.y && pointVector[i + 1].y < objectPosition.y) ||
            (pointVector[i].y < objectPosition.y && pointVector[i + 1].y > objectPosition.y)) {
            double a = (pointVector[i + 1].y - pointVector[i].y) / (pointVector[i + 1].x - pointVector[i].x);
            double b = pointVector[i].y - pointVector[i].x * a;

            if ((a >= 0 && objectPosition.y >= objectPosition.x * a + b) || (a <= 0 && objectPosition.y <= objectPosition.x * a + b)) {
                counter++;
            }
        }
    }

    return (counter % 2 == 1 ? TRUE : FALSE);
}

- (void)hitTestOSCAtMousePositionX:(double)mousePositionX
                    mousePositionY:(double)mousePositionY
                        activePart:(NSInteger *)activePart
                            atTime:(CMTime)time {
    id<FxOnScreenControlAPI_v4> oscAPI = [_apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    [oscAPI setCursor:[NSCursor arrowCursor]];
    CGPoint objectPosition = {0.0, 0.0};
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_CANVAS
                            fromX:mousePositionX
                            fromY:mousePositionY
                          toSpace:kFxDrawingCoordinates_OBJECT
                              toX:&objectPosition.x
                              toY:&objectPosition.y];
    *activePart = AP_Null;
    id<FxParameterRetrievalAPI_v6> paramAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    
    /// Initialazing parameter manager
    ParameterManager paramManager;
    paramManager.setRetrievalApi(paramAPI);
    
    /// Collecting vertices number, effect type and circle blur radius
    int et;
    paramManager.getIntValue(&et, PF_EffectTypes, time);
    int vertices = 0;
    paramManager.getIntValue(&vertices, PF_BasicOSCMenu, time);
    float circleRadius = 0.0;
    paramManager.getFloatValue(&circleRadius, PF_CircleBlurRadius, time);
    
    /// Hit test for circle blur effect
    if ([self checkCircleHitTest:activePart
                    circleRadius:circleRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_CircleBlurLocation
                            time:time]) {
        if (et == ET_Blur) {
            *activePart = AP_CircleBlur;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }
    /// Hit test for fish eye effect
    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_FishEyeLocation
                            time:time]) {
        if (et == ET_SpecialEffect) {
            *activePart = AP_FishEye;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }
    /// Hit test for lens flare effect
    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_LensFlareLocation
                            time:time]) {
        if (et == ET_LensFlare) {
            *activePart = AP_LensFlare;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition1
                            time:time]) {
        if (et == ET_Basic && vertices >= 1) {
            *activePart = AP_Basic1;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition2
                            time:time]) {
        if (et == ET_Basic && vertices >= 1) {
            *activePart = AP_Basic2;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition3
                            time:time]) {
        if (et == ET_Basic && vertices >= 1) {
            *activePart = AP_Basic3;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition4
                            time:time]) {
        if (et == ET_Basic && vertices >= 2) {
            *activePart = AP_Basic4;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition5
                            time:time]) {
        if (et == ET_Basic && vertices >= 3) {
            *activePart = AP_Basic5;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition6
                            time:time]) {
        if (et == ET_Basic && vertices >= 4) {
            *activePart = AP_Basic6;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition7
                            time:time]) {
        if (et == ET_Basic && vertices >= 5) {
            *activePart = AP_Basic7;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition8
                            time:time]) {
        if (et == ET_Basic && vertices >= 6) {
            *activePart = AP_Basic8;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition9
                            time:time]) {
        if (et == ET_Basic && vertices >= 7) {
            *activePart = AP_Basic9;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition10
                            time:time]) {
        if (et == ET_Basic && vertices >= 8) {
            *activePart = AP_Basic10;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition11
                            time:time]) {
        if (et == ET_Basic && vertices >= 9) {
            *activePart = AP_Basic11;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkCircleHitTest:activePart
                    circleRadius:_smallRadius
                          oscAPI:oscAPI
                    parameterAPI:paramAPI
                  objectPosition:objectPosition
                            flag:PF_BasicPosition12
                            time:time]) {
        if (et == ET_Basic && vertices >= 10) {
            *activePart = AP_Basic12;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }

    if ([self checkPolygonHitTest:objectPosition paramAPI:paramAPI atTime:time]) {
        if (et == ET_Basic) {
            *activePart = AP_BasicOSC;
            [oscAPI setCursor:[NSCursor openHandCursor]];
            return;
        }
    }
}

- (void)keyDownAtPositionX:(double)mousePositionX
                 positionY:(double)mousePositionY
                keyPressed:(unsigned short)asciiKey
                 modifiers:(FxModifierKeys)modifiers
               forceUpdate:(BOOL *)forceUpdate
                 didHandle:(BOOL *)didHandle
                    atTime:(CMTime)time {
    /// Handling key events if caps lock is pressed
    if (modifiers == kFxModifierKey_CAPS_LOCK) {
        id<FxParameterRetrievalAPI_v6> paramGetAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
        id<FxParameterSettingAPI_v5> paramSetAPI = [_apiManager apiForProtocol:@protocol(FxParameterSettingAPI_v5)];
        /// Initializing parameter manager
        ParameterManager paramManager;
        paramManager.setRetrievalApi(paramGetAPI);
        paramManager.setParamSetApi(paramSetAPI);
        
        /// Getting popup menu values in which osc is generated
        int et, bt, st;
        paramManager.getIntValue(&et, PF_EffectTypes, time);
        paramManager.getIntValue(&bt, PF_BlurTypes, time);
        paramManager.getIntValue(&st, PF_SpecialEffectsTypes, time);

        /// Checking if currently chosen effect has osc, if not returning
        if ((et == ET_Blur && bt != BT_CircleBlur) && (et == ET_SpecialEffect && st != ST_FishEye) && (et != ET_LensFlare))
            return;

        switch (et) {
            /// Handling blur osc key events
            case ET_Blur: {
                /// Move circle right
                if (asciiKey == 63235) {
                    paramManager.swapPointValues(0.01, 0.0, PF_CircleBlurLocation, time);
                }
                /// Move circle up
                else if (asciiKey == 63232) {
                    paramManager.swapPointValues(0.0, 0.01, PF_CircleBlurLocation, time);
                }
                /// Move circle left
                else if (asciiKey == 63234) {
                    paramManager.swapPointValues(-0.01, 0.0, PF_CircleBlurLocation, time);
                }
                /// Move circle down
                else if (asciiKey == 63233) {
                    paramManager.swapPointValues(0.0, -0.01, PF_CircleBlurLocation, time);
                }
                /// 'p'
                else if (asciiKey == 80) {
                    // Change blur radius to bigger
                    paramManager.swapIntValues(1, PF_CircleBlurAmount, time);
                }
                /// 'o'
                else if (asciiKey == 79) {
                    // Change blur radius to smaller
                    paramManager.swapIntValues(-1, PF_CircleBlurAmount, time);
                }
                /// 'm'
                else if (asciiKey == 77) {
                    /// Change circle radius to bigger one
                    paramManager.swapFloatValues(0.05, PF_CircleBlurAmount, time);
                }
                /// 'n'
                else if (asciiKey == 78) {
                    /// Change circl;e radius to smaller one
                    paramManager.swapFloatValues(-0.05, PF_CircleBlurAmount, time);
                }

                // Change smooth edges on and off - 's'
                else if (asciiKey == 83) {
                    paramManager.swapBoolValues(PF_CircleBlurSmooth, time);
                }

                break;
            }
            /// Handling fish eye effect osc key events
            case ET_SpecialEffect: {
                /// Move circle right
                if (asciiKey == 63235) {
                    paramManager.swapPointValues(0.01, 0.0, PF_FishEyeLocation, time);
                }
                /// Move circle up
                else if (asciiKey == 63232) {
                    paramManager.swapPointValues(0.0, 0.01, PF_FishEyeLocation, time);
                }
                /// Move circle left
                else if (asciiKey == 63234) {
                    paramManager.swapPointValues(-0.01, 0.0, PF_FishEyeLocation, time);
                }
                /// Move circle down
                else if (asciiKey == 63233) {
                    paramManager.swapPointValues(0.0, -0.01, PF_FishEyeLocation, time);
                }
                /// 'p'
                else if (asciiKey == 80) {
                    // Change amount to bigger
                    paramManager.swapFloatValues(5.0, PF_FishEyeAmount, time);
                }
                /// 'o'
                else if (asciiKey == 79) {
                    // Change amount to smaller
                    paramManager.swapFloatValues(-5.0, PF_FishEyeAmount, time);
                }

                /// 'm'
                else if (asciiKey == 77) {
                    /// Change radius to bigger one
                    paramManager.swapFloatValues(0.05, PF_FishEyeRadius, time);
                }

                /// 'n'
                else if (asciiKey == 78) {
                    /// Change radius to smaller one
                    paramManager.swapFloatValues(-0.05, PF_FishEyeRadius, time);
                }
            }
            /// Handling lens flare osc key events
            case ET_LensFlare: {
                /// Move circle right
                if (asciiKey == 63235) {
                    paramManager.swapPointValues(0.01, 0.0, PF_LensFlareLocation, time);
                }
                /// Move circle up
                else if (asciiKey == 63232) {
                    paramManager.swapPointValues(0.0, 0.01, PF_LensFlareLocation, time);
                }
                /// Move circle left
                else if (asciiKey == 63234) {
                    paramManager.swapPointValues(-0.01, 0.0, PF_LensFlareLocation, time);
                }
                /// Move circle down
                else if (asciiKey == 63233) {
                    paramManager.swapPointValues(0.0, -0.01, PF_LensFlareLocation, time);
                }
                /// 'p'
                else if (asciiKey == 80) {
                    // Change FLARE STRENGTH to bigger
                    paramManager.swapFloatValues(0.1, PF_LensFlareStrength, time);
                }
                /// 'o'
                else if (asciiKey == 79) {
                    // Change FLARE STRENGTH  to smaller
                    paramManager.swapFloatValues(-0.1, PF_LensFlareStrength, time);
                }
                /// 'm'
                else if (asciiKey == 77) {
                    /// Change ANFLARE INTENSITY to bigger one
                    paramManager.swapFloatValues(10.0, PF_LensFlareIntensityOfLight, time);
                }
                /// 'n'
                else if (asciiKey == 78) {
                    /// Change ANFLARE INTENSITY to smaller one
                    paramManager.swapFloatValues(-10.0, PF_LensFlareIntensityOfLight, time);
                }
                /// 'k'
                else if (asciiKey == 75) {
                    /// Change ANFLARE STRETCH to smaller one
                    paramManager.swapFloatValues(-0.01, PF_LensFlareStretch, time);
                }
                /// 'l'
                else if (asciiKey == 76) {
                    /// Change ANFLARE STRETCH to bigger one
                    paramManager.swapFloatValues(0.01, PF_LensFlareStretch, time);
                }
                /// 'h'
                else if (asciiKey == 71) {
                    /// Change ANFLARE BRIGHTNESS to smaller one
                    paramManager.swapFloatValues(-0.01, PF_LensFlareBrightness, time);
                }
                /// 'g'
                else if (asciiKey == 72) {
                    /// Change ANFLARE BRIGHTNESS to bigger one
                    paramManager.swapFloatValues(0.01, PF_LensFlareBrightness, time);
                }
                // 's'
                else if (asciiKey == 83) {
                    /// Show or hide frame
                    paramManager.swapBoolValues(PF_LensFlareShowImage, time);
                }
                break;
            }
            default:
                break;
        }
    }

    *forceUpdate = YES;
    *didHandle = YES;
}

/// Method for handling key up event (left as default)
- (void)keyUpAtPositionX:(double)mousePositionX
               positionY:(double)mousePositionY
              keyPressed:(unsigned short)asciiKey
               modifiers:(FxModifierKeys)modifiers
             forceUpdate:(BOOL *)forceUpdate
               didHandle:(BOOL *)didHandle
                  atTime:(CMTime)time {
    *didHandle = NO;
}

/// Method for handling mouse down event
- (void)mouseDownAtPositionX:(double)mousePositionX
                   positionY:(double)mousePositionY
                  activePart:(NSInteger)activePart
                   modifiers:(FxModifierKeys)modifiers
                 forceUpdate:(BOOL *)forceUpdate
                      atTime:(CMTime)time {
    id<FxOnScreenControlAPI_v4> oscAPI = [_apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    /// Setting closed hand cursor
    [oscAPI setCursor:[NSCursor closedHandCursor]];
    /// Locking to prevent data race
    [lastPositionLock lock];
    /// Saving the new position of mouse in _mousePosition
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_CANVAS
                            fromX:mousePositionX
                            fromY:mousePositionY
                          toSpace:kFxDrawingCoordinates_OBJECT
                              toX:&_mousePosition.x
                              toY:&_mousePosition.y];
    /// Unlocking
    [lastPositionLock unlock];
    *forceUpdate = NO;
}

/// Method used in hadnling mouse dragging event
- (void)mouseDraggedAtPositionX:(double)mousePositionX
                      positionY:(double)mousePositionY
                     activePart:(NSInteger)activePart
                      modifiers:(FxModifierKeys)modifiers
                    forceUpdate:(BOOL *)forceUpdate
                         atTime:(CMTime)time {
    id<FxOnScreenControlAPI_v4> oscAPI = [_apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    CGPoint objectPos = {0.0, 0.0};
    /// Getting the current position of mouse in object space
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_CANVAS
                            fromX:mousePositionX
                            fromY:mousePositionY
                          toSpace:kFxDrawingCoordinates_OBJECT
                              toX:&objectPos.x
                              toY:&objectPos.y];

    [lastPositionLock lock];
    /// Updating the current mouse position
    CGPoint delta = {objectPos.x - _mousePosition.x, objectPos.y - _mousePosition.y};
    _mousePosition = objectPos;
    [lastPositionLock unlock];

    id<FxParameterSettingAPI_v5> paramSetAPI = [_apiManager apiForProtocol:@protocol(FxParameterSettingAPI_v5)];
    id<FxParameterRetrievalAPI_v6> paramGetAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    
    /// Initializing parameter manager
    ParameterManager paramManager;
    paramManager.setParamSetApi(paramSetAPI);
    paramManager.setRetrievalApi(paramGetAPI);
    
    /// Handling the movement of osc elements based on part, which is currently clicked
    if (activePart == AP_CircleBlur) {
        paramManager.swapPointValues(delta.x, delta.y, PF_CircleBlurLocation, time);
    }

    else if (activePart == AP_FishEye) {
        paramManager.swapPointValues(delta.x, delta.y, PF_FishEyeLocation, time);
    }

    else if (activePart == AP_LensFlare) {
        paramManager.swapPointValues(delta.x, delta.y, PF_LensFlareLocation, time);
    }

    else if (activePart == AP_Basic1) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition1, time);
    }

    else if (activePart == AP_Basic2) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition2, time);
    }

    else if (activePart == AP_Basic3) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition3, time);
    }

    else if (activePart == AP_Basic4) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition4, time);
    }

    else if (activePart == AP_Basic5) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition5, time);
    }

    else if (activePart == AP_Basic6) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition6, time);
    }

    else if (activePart == AP_Basic7) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition7, time);
    }

    else if (activePart == AP_Basic8) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition8, time);
    }

    else if (activePart == AP_Basic9) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition9, time);
    }

    else if (activePart == AP_Basic10) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition10, time);
    }

    else if (activePart == AP_Basic11) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition12, time);
    }

    else if (activePart == AP_Basic12) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition12, time);
    }

    else if (activePart == AP_BasicOSC) {
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition1, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition2, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition3, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition4, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition5, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition6, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition7, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition8, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition9, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition10, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition11, time);
        paramManager.swapPointValues(delta.x, delta.y, PF_BasicPosition12, time);
    }

    *forceUpdate = YES;
}

- (void)mouseUpAtPositionX:(double)mousePositionX
                 positionY:(double)mousePositionY
                activePart:(NSInteger)activePart
                 modifiers:(FxModifierKeys)modifiers
               forceUpdate:(BOOL *)forceUpdate
                    atTime:(CMTime)time {
    id<FxOnScreenControlAPI_v4> oscAPI = [_apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    /// Setting open hand cursor
    [oscAPI setCursor:[NSCursor openHandCursor]];
    /// Updating current mouse position by invoking mouseDraggedAtPosition and then 
    [self mouseDraggedAtPositionX:mousePositionX
                        positionY:mousePositionY
                       activePart:activePart
                        modifiers:modifiers
                      forceUpdate:forceUpdate
                           atTime:time];

    [lastPositionLock lock];
    /// Setting last mouse position to be outside of image bounds
    _mousePosition = CGPointMake(-1.0, -1.0);
    [lastPositionLock unlock];
}

@end
