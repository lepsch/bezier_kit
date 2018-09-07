//
//  PathTest.swift
//  BezierKit
//
//  Created by Holmes Futrell on 8/1/18.
//  Copyright © 2018 Holmes Futrell. All rights reserved.
//

import XCTest
@testable import BezierKit

class PathTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitCGPathEmpty() {
        // trivial test of an empty path
        let path = Path(cgPath: CGMutablePath())
        XCTAssert(path.subpaths.isEmpty)
    }
    
    func testInitCGPathRect() {
        
        // simple test of a rectangle (note that this CGPath uses a moveTo())
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1, height: 2))
        let cgPath1 = CGPath(rect: rect, transform: nil)
        let path1 = Path(cgPath: cgPath1)
        
        let p1 = CGPoint(x: 0.0, y: 0.0)
        let p2 = CGPoint(x: 1.0, y: 0.0)
        let p3 = CGPoint(x: 1.0, y: 2.0)
        let p4 = CGPoint(x: 0.0, y: 2.0)
        
        XCTAssertEqual(path1.subpaths.count, 1)
        XCTAssertEqual(path1.subpaths[0].curves[0] as! LineSegment, LineSegment(p0: p1, p1: p2))
        XCTAssertEqual(path1.subpaths[0].curves[1] as! LineSegment, LineSegment(p0: p2, p1: p3))
        XCTAssertEqual(path1.subpaths[0].curves[2] as! LineSegment, LineSegment(p0: p3, p1: p4))
        XCTAssertEqual(path1.subpaths[0].curves[3] as! LineSegment, LineSegment(p0: p4, p1: p1))
    }
    
    func testInitCGPathEllipse() {
        // test of a ellipse (4 cubic curves)
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1, height: 2))
        let cgPath2 = CGPath(ellipseIn: rect, transform: nil)
        let path2 = Path(cgPath: cgPath2)

        let p1 = CGPoint(x: 1.0, y: 1.0)
        let p2 = CGPoint(x: 0.5, y: 2.0)
        let p3 = CGPoint(x: 0.0, y: 1.0)
        let p4 = CGPoint(x: 0.5, y: 0.0)
        
        XCTAssertEqual(path2.subpaths.count, 1)
        XCTAssertEqual(path2.subpaths[0].curves.count, 4)
        XCTAssertEqual(path2.subpaths[0].curves[0].startingPoint, p1)
        XCTAssertEqual(path2.subpaths[0].curves[1].startingPoint, p2)
        XCTAssertEqual(path2.subpaths[0].curves[2].startingPoint, p3)
        XCTAssertEqual(path2.subpaths[0].curves[3].startingPoint, p4)
        XCTAssertEqual(path2.subpaths[0].curves[0].endingPoint, p2)
        XCTAssertEqual(path2.subpaths[0].curves[1].endingPoint, p3)
        XCTAssertEqual(path2.subpaths[0].curves[2].endingPoint, p4)
        XCTAssertEqual(path2.subpaths[0].curves[3].endingPoint, p1)
    }
        
    func testInitCGPathQuads() {
        // test of a rect with some quad curves
        let cgPath3 = CGMutablePath()
        
        let p1 = CGPoint(x: 0.0, y: 1.0)
        let p2 = CGPoint(x: 2.0, y: 1.0)
        let p3 = CGPoint(x: 3.0, y: 0.5)
        let p4 = CGPoint(x: 2.0, y: 0.0)
        let p5 = CGPoint(x: 0.0, y: 0.0)
        let p6 = CGPoint(x: -1.0, y: 0.5)
        
        cgPath3.move(to: p1)
        cgPath3.addLine(to: p2)
        cgPath3.addQuadCurve(to: p4, control: p3)
        cgPath3.addLine(to: p5)
        cgPath3.addQuadCurve(to: p1, control: p6)
        cgPath3.closeSubpath()
        
        let path3 = Path(cgPath: cgPath3)
        XCTAssertEqual(path3.subpaths.count, 1)
        XCTAssertEqual(path3.subpaths[0].curves.count, 4)
        XCTAssertEqual(path3.subpaths[0].curves[1] as! QuadraticBezierCurve, QuadraticBezierCurve(p0: p2, p1: p3, p2: p4))
    }
    
    func testInitCGPathMultipleSubpaths() {
        // test of 2 line segments where each segment is started with a moveTo
        // this tests multiple subpaths and starting new paths with moveTo instead of closePath
        let cgPath4 = CGMutablePath()
        let p1 = CGPoint(x: 1.0, y: 2.0)
        let p2 = CGPoint(x: 3.0, y: 5.0)
        let p3 = CGPoint(x: -4.0, y: -1.0)
        let p4 = CGPoint(x: 5.0, y: 3.0)
        
        cgPath4.move(to: p1)
        cgPath4.addLine(to: p2)
        cgPath4.move(to: p3)
        cgPath4.addLine(to: p4)
        
        let path4 = Path(cgPath: cgPath4)
        XCTAssertEqual(path4.subpaths.count, 2)
        XCTAssertEqual(path4.subpaths[0].curves.count, 1)
        XCTAssertEqual(path4.subpaths[1].curves.count, 1)
        XCTAssertEqual(path4.subpaths[0].curves[0] as! LineSegment, LineSegment(p0: p1, p1: p2))
        XCTAssertEqual(path4.subpaths[1].curves[0] as! LineSegment, LineSegment(p0: p3, p1: p4))
    }
    
    func testIntersects() {

        // TODO: improved unit tests ... currently this test is very lax and allows duplicated intersections
        let circleCGPath = CGMutablePath()
        circleCGPath.addEllipse(in: CGRect(origin: CGPoint(x: 2.0, y: 3.0), size: CGSize(width: 2.0, height: 2.0)))
        
        let circlePath = Path(cgPath: circleCGPath) // a circle centered at (3, 4) with radius 2
        
        let rectangleCGPath = CGMutablePath()
        rectangleCGPath.addRect(CGRect(origin: CGPoint(x: 3.0, y: 4.0), size: CGSize(width: 2.0, height: 2.0)))
        
        let rectanglePath = Path(cgPath: rectangleCGPath)
        
        let intersections = rectanglePath.intersects(path: circlePath).map { rectanglePath.point(at: $0.indexedPathLocation1 ) }
        
        XCTAssert(intersections.contains(CGPoint(x: 4.0, y: 4.0)))
        XCTAssert(intersections.contains(CGPoint(x: 3.0, y: 5.0)))
    }
    
    func testPointIsWithinDistanceOfBoundary() {
        
        let circleCGPath = CGMutablePath()
        circleCGPath.addEllipse(in: CGRect(origin: CGPoint(x: -1.0, y: -1.0), size: CGSize(width: 2.0, height: 2.0)))

        let circlePath = Path(cgPath: circleCGPath) // a circle centered at origin with radius 1
        
        let d = CGFloat(0.1)
        let p1 = CGPoint(x: -3.0, y: 0.0)
        let p2 = CGPoint(x: -0.9, y: 0.9)
        let p3 = CGPoint(x: 0.75, y: 0.75)
        let p4 = CGPoint(x: 0.5, y: 0.5)

        XCTAssertFalse(circlePath.pointIsWithinDistanceOfBoundary(point: p1, distance: d)) // no, path bounding box isn't even within that distance
        XCTAssertFalse(circlePath.pointIsWithinDistanceOfBoundary(point: p2, distance: d)) // no, within bounding box, but no individual curves are within that distance
        XCTAssertTrue(circlePath.pointIsWithinDistanceOfBoundary(point: p3, distance: d))  // yes, one of the curves that makes up the circle is within that distance
        XCTAssertTrue(circlePath.pointIsWithinDistanceOfBoundary(point: p3, distance: CGFloat(10.0)))  // yes, so obviously within that distance implementation should early return yes
        XCTAssertFalse(circlePath.pointIsWithinDistanceOfBoundary(point: p4, distance: d)) // no, we are inside the path but too far from the boundary
        
    }
    
    func testEquatable() {
        let rect = CGRect(origin: CGPoint(x: -1, y: -1), size: CGSize(width: 2, height: 2))
        let path1 = Path(cgPath: CGPath(rect: rect, transform: nil))
        let path2 = Path(cgPath: CGPath(ellipseIn: rect, transform: nil))
        let path3 = Path(cgPath: CGPath(rect: rect, transform: nil))
        XCTAssertNotEqual(path1, path2)
        XCTAssertEqual(path1, path3)
    }
    
    func testIsEqual() {
        let rect = CGRect(origin: CGPoint(x: -1, y: -1), size: CGSize(width: 2, height: 2))
        let path1 = Path(cgPath: CGPath(rect: rect, transform: nil))
        let path2 = Path(cgPath: CGPath(ellipseIn: rect, transform: nil))
        let path3 = Path(cgPath: CGPath(rect: rect, transform: nil))
        
        let string = "hello" as NSString
        
        XCTAssertFalse(path1.isEqual(nil))
        XCTAssertFalse(path1.isEqual(string))
        XCTAssertFalse(path1.isEqual(path2))
        XCTAssertTrue(path1.isEqual(path3))
    }
    
    func testEncodeDecode() {
        let rect = CGRect(origin: CGPoint(x: -1, y: -1), size: CGSize(width: 2, height: 2))
        let path = Path(cgPath: CGPath(rect: rect, transform: nil))
        let data = NSKeyedArchiver.archivedData(withRootObject: path)
        let decodedPath = NSKeyedUnarchiver.unarchiveObject(with: data) as! Path
        XCTAssertEqual(decodedPath, path)
    }
    
    // MARK: - contains
    
    func testContainsSimple1() {
        let rect = CGRect(origin: CGPoint(x: -1, y: -1), size: CGSize(width: 2, height: 2))
        let path = Path(cgPath: CGPath(rect: rect, transform: nil))
        XCTAssertFalse(path.contains(CGPoint(x: -2, y: 0))) // the first point is outside the rectangle on the left
        XCTAssertTrue(path.contains(CGPoint(x: 0, y: 0)))  // the second point falls inside the rectangle
        XCTAssertFalse(path.contains(CGPoint(x: 3, y: 0))) // the third point falls outside the rectangle on the right
    }
    
    func testContainsSimple2() {
        let rect = CGRect(origin: CGPoint(x: -1, y: -1), size: CGSize(width: 2, height: 2))
        let path = Path(cgPath: CGPath(ellipseIn: rect, transform: nil))
        XCTAssertFalse(path.contains(CGPoint(x: 5, y: 5)))       // the first point is way outside the circle
        XCTAssertFalse(path.contains(CGPoint(x: -0.8, y: -0.8))) // the second point is outside the circle, but within the bounding rect
        XCTAssertTrue(path.contains(CGPoint(x: 0.3, y: 0.3)))    // the third point falls inside the circle
        
        // the 4th point falls inside the and is a tricky case when using the evenOdd fill mode because it aligns with two path elements exactly at y = 0
        XCTAssertTrue(path.contains(CGPoint(x: 0.5, y: 0.0), using: .evenOdd))
        XCTAssertTrue(path.contains(CGPoint(x: 0.5, y: 0.0), using: .winding))
        
        // the 5th point falls outside the circle, but drawing a horizontal line has a glancing blow with it
        XCTAssertFalse(path.contains(CGPoint(x: 0.1, y: 1.0), using: .evenOdd))
        XCTAssertFalse(path.contains(CGPoint(x: 0.1, y: -1.0), using: .winding))
    }

    func testContainsStar() {
        let starPoints = stride(from: 0.0, to: 2.0 * Double.pi, by: 0.4 * Double.pi).map { CGPoint(x: cos($0), y: sin($0)) }
        let cgPath = CGMutablePath()
        
        cgPath.move(to: starPoints[0])
        cgPath.addLine(to: starPoints[3])
        cgPath.addLine(to: starPoints[1])
        cgPath.addLine(to: starPoints[4])
        cgPath.addLine(to: starPoints[2])
        cgPath.closeSubpath()

        let path = Path(cgPath: cgPath)
        
        // check a point outside of the star
        let outsidePoint = CGPoint(x: 0.5, y: -0.5)
        XCTAssertFalse(path.contains(outsidePoint, using: .evenOdd))
        XCTAssertFalse(path.contains(outsidePoint, using: .winding))
        
        // using the winding rule, the center of the star is in the path, but with even-odd it's not
        XCTAssertTrue(path.contains(CGPoint.zero, using: .winding))
        XCTAssertFalse(path.contains(CGPoint.zero, using: .evenOdd))

        // check a point inside one of the star's arms
        let armPoint = CGPoint(x: 0.9, y: 0.0)
        XCTAssertTrue(path.contains(armPoint, using: .winding))
        XCTAssertTrue(path.contains(armPoint, using: .evenOdd))

        // check the edge case of the star's corners
        for i in 0..<5 {
            let point = starPoints[i] + CGPoint(x: 0.1, y: 0.0)
            XCTAssertFalse(path.contains(point, using: .evenOdd), "point \(i)")
            XCTAssertFalse(path.contains(point, using: .winding), "point \(i)")
        }
    }
    
    func testContainsCircleWithHole() {
        let rect1 = CGRect(origin: CGPoint(x: -3, y: -3), size: CGSize(width: 6, height: 6))
        let circlePath = Path(cgPath: CGPath(ellipseIn: rect1, transform: nil))
        let rect2 = CGRect(origin: CGPoint(x: -1, y: -1), size: CGSize(width: 2, height: 2))
        let reversedCirclePath = Path(cgPath: CGPath(ellipseIn: rect2, transform: nil)).reversed()
        let circleWithHole = Path(subpaths: circlePath.subpaths + reversedCirclePath.subpaths)
        XCTAssertFalse(circleWithHole.contains(CGPoint(x: 0.0, y: 0.0), using: .evenOdd))
        XCTAssertFalse(circleWithHole.contains(CGPoint(x: 0.0, y: 0.0), using: .winding))
        XCTAssertTrue(circleWithHole.contains(CGPoint(x: 2.0, y: 0.0), using: .evenOdd))
        XCTAssertTrue(circleWithHole.contains(CGPoint(x: 2.0, y: 0.0), using: .winding))
        XCTAssertFalse(circleWithHole.contains(CGPoint(x: 4.0, y: 0.0), using: .evenOdd))
        XCTAssertFalse(circleWithHole.contains(CGPoint(x: 4.0, y: 0.0), using: .winding))
    }
    
    // MARK: - vector boolean operations
    
    private func componentsEqualAsideFromElementOrdering(_ component1: PathComponent, _ component2: PathComponent) -> Bool {
        let curves1 = component1.curves
        let curves2 = component2.curves
        guard curves1.count == curves2.count else {
            return false
        }
        if curves1.isEmpty {
            return true
        }
        guard let offset = curves2.index(where: { $0 == curves1.first! }) else {
            return false
        }
        let count = curves1.count
        for i in 0..<count {
            guard curves1[i] == curves2[(i+offset) % count] else {
                return false
            }
        }
        return true
    }
    
    // points on the first square
    let p0 = CGPoint(x: 0.0, y: 0.0)
    let p1 = CGPoint(x: 1.0, y: 0.0) // intersection 1
    let p2 = CGPoint(x: 2.0, y: 0.0)
    let p3 = CGPoint(x: 2.0, y: 1.0) // intersection 2
    let p4 = CGPoint(x: 2.0, y: 2.0)
    let p5 = CGPoint(x: 0.0, y: 2.0)
    
    // points on the second square
    let p6 = CGPoint(x: 1.0, y: -1.0)
    let p7 = CGPoint(x: 3.0, y: -1.0)
    let p8 = CGPoint(x: 3.0, y: 1.0)
    let p9 = CGPoint(x: 1.0, y: 1.0)
    
    private func createSquare1() -> Path {
        return Path(subpaths: [PathComponent(curves:
            [
                LineSegment(p0: p0, p1: p2),
                LineSegment(p0: p2, p1: p4),
                LineSegment(p0: p4, p1: p5),
                LineSegment(p0: p5, p1: p0)
            ]
        )])
    }
    
    private func createSquare2() -> Path {
        return Path(subpaths: [PathComponent(curves:
        [
            LineSegment(p0: p6, p1: p7),
            LineSegment(p0: p7, p1: p8),
            LineSegment(p0: p8, p1: p9),
            LineSegment(p0: p9, p1: p6)
        ]
    )])
    }
    
    func testSubtracting() {
        let expectedResult = Path(subpaths: [PathComponent(curves:
            [
                LineSegment(p0: p1, p1: p9),
                LineSegment(p0: p9, p1: p3),
                LineSegment(p0: p3, p1: p4),
                LineSegment(p0: p4, p1: p5),
                LineSegment(p0: p5, p1: p0),
                LineSegment(p0: p0, p1: p1)
            ]
        )])
        let square1 = createSquare1()
        let square2 = createSquare2()
        let subtracted = square1.subtracting(square2)
        XCTAssertEqual(subtracted.subpaths.count, 1)
        XCTAssert(
            componentsEqualAsideFromElementOrdering(subtracted.subpaths[0], expectedResult.subpaths[0])
        )
    }
    
    func testUnion() {
        let expectedResult = Path(subpaths: [PathComponent(curves:
            [
                LineSegment(p0: p0, p1: p1),
                LineSegment(p0: p1, p1: p6),
                LineSegment(p0: p6, p1: p7),
                LineSegment(p0: p7, p1: p8),
                LineSegment(p0: p8, p1: p3),
                LineSegment(p0: p3, p1: p4),
                LineSegment(p0: p4, p1: p5),
                LineSegment(p0: p5, p1: p0)
            ]
        )])
        let square1 = createSquare1()
        let square2 = createSquare2()
        let unioned = square1.union(square2)
        XCTAssertEqual(unioned.subpaths.count, 1)
        XCTAssert(
            componentsEqualAsideFromElementOrdering(unioned.subpaths[0], expectedResult.subpaths[0])
        )
    }
    
    func testIntersecting() {
        let expectedResult = Path(subpaths: [PathComponent(curves:
            [
                LineSegment(p0: p1, p1: p2),
                LineSegment(p0: p2, p1: p3),
                LineSegment(p0: p3, p1: p9),
                LineSegment(p0: p9, p1: p1)
            ]
        )])
        let square1 = createSquare1()
        let square2 = createSquare2()
        let intersected = square1.intersecting(square2)
        XCTAssertEqual(intersected.subpaths.count, 1)
        XCTAssert(
            componentsEqualAsideFromElementOrdering(intersected.subpaths[0], expectedResult.subpaths[0])
        )
    }
    
    func testSubtractWindingDirection() {
        // this is a specific test of `subtracting` to ensure that when a component creates a "hole"
        // the order of the hole is reversed so that it is not contained in the shape when using .winding fill rule
        let circle   = Path(cgPath: CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 3, height: 3), transform: nil))
        let hole     = Path(cgPath: CGPath(ellipseIn: CGRect(x: 1, y: 1, width: 1, height: 1), transform: nil))
        let donut    = circle.subtracting(hole)
        XCTAssertTrue(donut.contains(CGPoint(x: 0.5, y: 0.5), using: .winding))  // inside the donut (but not the hole)
        XCTAssertFalse(donut.contains(CGPoint(x: 1.5, y: 1.5), using: .winding)) // center of donut hole
    }
    
}
