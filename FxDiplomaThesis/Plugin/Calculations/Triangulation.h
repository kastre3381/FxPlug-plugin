#import <FxPlug/FxPlugSDK.h>
#import <algorithm>
#import <cmath>
#import <iostream>
#import <numeric>
#import <vector>

struct Triangulation {
    Triangulation() = default;
    
    /// Method used to calculate cross values between two vectors
    static double cross(const CGPoint &p1, const CGPoint &p2);
    /// Method used to calculate area of triagle described by its vertices
    static double area(const CGPoint &p1, const CGPoint &p2, const CGPoint &p3);
    /// Method used to determine, if point p lies within boundaries of triangle defined by points p1, p2, p3
    static bool containsPoint(const CGPoint &p1, const CGPoint &p2, const CGPoint &p3, const CGPoint &p);
    /// Method used to determin if angle is convex
    static bool isConvex(const CGPoint &p1, const CGPoint &p2, const CGPoint &p3);
    /// Method used to delete points which lie on the same line
    static bool deletePointsOnTheSameLine(const CGPoint &p1, const CGPoint &p2, const CGPoint &p3);
    /// Method used for getting index of polygon vertice
    static int getPointAtIndex(const std::vector<int> &points, int index);
    /// Method used for calculating the vertices of polygon after triangulation
    static std::vector<CGPoint> getTriangulation(std::vector<CGPoint> points);
};
