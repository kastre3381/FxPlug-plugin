#import "Triangulation.h"

double Triangulation::cross(const CGPoint &p1, const CGPoint &p2) {
    return p1.x * p2.y - p1.y * p2.x;
}

double Triangulation::area(const CGPoint &p1, const CGPoint &p2, const CGPoint &p3) {
    /// Calculating area by using Gauss's area formula
    return 0.5 * std::fabs(p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y));
}

bool Triangulation::containsPoint(const CGPoint &p1, const CGPoint &p2, const CGPoint &p3, const CGPoint &p) {
    /// Calculating the area of main triangle and triangles
    /// created from two points of this triangle and the point
    /// for which we want to determine if it lies inside triangle
    ///
    /// If the difference of the main triangle area and the rest 3 areas
    /// is smaller than 1e-8 the point lies inside triangle
    return std::fabs(area(p1, p2, p3) - area(p1, p2, p) - area(p1, p3, p) - area(p2, p3, p)) < 1e-8;
}

bool Triangulation::isConvex(const CGPoint &p1, const CGPoint &p2, const CGPoint &p3) {
    CGPoint p12 = {p2.x - p1.x, p2.y - p1.y}, p23 = {p3.x - p2.x, p3.y - p2.y};
    return cross(p12, p23) < 0.0;
}

bool Triangulation::deletePointsOnTheSameLine(const CGPoint &p1, const CGPoint &p2, const CGPoint &p3) {
    CGPoint p12 = {p2.x - p1.x, p2.y - p1.y}, p23 = {p3.x - p2.x, p3.y - p2.y};
    return std::fabs(cross(p12, p23)) < 1e-8;
}

int Triangulation::getPointAtIndex(const std::vector<int> &points, int index) {
    return points.at((index + points.size()) % points.size());
}

std::vector<CGPoint> Triangulation::getTriangulation(std::vector<CGPoint> points) {
    std::vector<CGPoint> res, newPoints;

    /// Deleting the points that lie on the same line
    for (int i = 0; i < points.size(); i++) {
        if (!deletePointsOnTheSameLine(points[(i + points.size() - 1) % points.size()], points[i], points[(i + 1) % points.size()])) {
            newPoints.push_back(points[i]);
        } else {
            std::cout << "Deleted point " << points[i].x << ", " << points[i].y << std::endl;
        }
    }

    points = newPoints;

    std::vector<int> indices(points.size());
    std::iota(indices.begin(), indices.end(), 0);
    auto pointsList = indices;

    /// If there are 3 points left, they define last triangle
    while (pointsList.size() > 3) {
        /// Variable used in stopping while loop after not founding the triangulation of polygon
        /// It can happen when the polygon is not simple, which means that it's edges intersect
        bool foundEar = false;
        for (int i = 0; i < pointsList.size(); i++) {
            int i1 = getPointAtIndex(pointsList, i - 1), i2 = pointsList[i], i3 = getPointAtIndex(pointsList, i + 1);
            CGPoint a = points[i1], b = points[i2], c = points[i3];

            if (!isConvex(a, b, c))
                continue;

            bool isEar = true;

            /// Searching for new triangle point
            for (int j = 0; j < points.size(); j++) {
                if (j == i1 || j == i2 || j == i3)
                    continue;

                if (containsPoint(a, b, c, points[j])) {
                    isEar = false;
                    break;
                }
            }

            if (isEar) {
                /// Adding new triangle
                res.push_back(points[i1]);
                res.push_back(points[i2]);
                res.push_back(points[i3]);

                foundEar = true;
                /// Erasing newly added vertex from points list
                pointsList.erase(pointsList.begin() + i);
                break;
            }
        }
        if (!foundEar) {
            std::cerr << "Wielokąt nie jest prosty" << std::endl;
            break;
        }
    }

    /// Adding last triangle
    res.push_back(points[pointsList[0]]);
    res.push_back(points[pointsList[1]]);
    res.push_back(points[pointsList[2]]);

    return res;
}
