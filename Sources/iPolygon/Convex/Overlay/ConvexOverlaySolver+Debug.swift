//
//  ConvexOverlaySolver+Debug.swift
//  
//
//  Created by Nail Sharipov on 23.05.2023.
//

import iFixFloat

#if DEBUG

public struct Convex {
    public static let empty = Convex(centroid: .zero, path: [])
    public let centroid: Centroid
    public let path: [FixVec]
}

public extension ConvexOverlaySolver {
    
    static func debugIntersect(a: [FixVec], b: [FixVec]) -> [ABResult] {
        var result: [ABResult] = []
        let pins = ConvexCrossSolver.intersect(polyA: a, polyB: b)

        guard !pins.isEmpty else { return [] }
        
        for i in 0..<pins.count {
            let pin0 = pins[i]
            let pin1 = pins.next(pin: pin0)
            
            let aPath = Self.directPoints(s0: pin0.a, s1: pin1.a, points: a)
            let bPath = Self.directPoints(s0: pin0.b, s1: pin1.b, points: b)
            
            let aSet = Set(aPath)
            assert(aSet.count == aPath.count)
            let bSet = Set(bPath)
            assert(bSet.count == bPath.count)

            let aArea = Self.directArea(s0: pin0.a, s1: pin1.a, points: a)
            let bArea = Self.directArea(s0: pin0.b, s1: pin1.b, points: b)
            
            let unsafeArea = aArea - bArea
            
            result.append(ABResult(a: aPath, b: bPath, unsafeArea: unsafeArea))
        }
        
        return result
    }
    
    
    private static func directPoints(s0: PointStone, s1: PointStone, points: [FixVec]) -> [FixVec] {
        guard s0.m != s1.m else {
            return []
        }

        var unsafeArea: [FixVec] = []

        unsafeArea.append(s0.p)

        if s0.m < s1.m {
            // example from 3 to 6

            var i = s0.m.index + 1
            
            let last = s1.m.offset == 0 ? s1.m.index : s1.m.index + 1
            
            while i < last {
                unsafeArea.append(points[i])
                i += 1
            }
        } else {
            // example from 5 to 2
            var i = s0.m.index + 1
            
            while i < points.count {
                unsafeArea.append(points[i])
                i += 1
            }

            i = 0
            let last = s1.m.offset == 0 ? s1.m.index : s1.m.index + 1
            
            while i < last {
                unsafeArea.append(points[i])
                i += 1
            }
        }
        
        unsafeArea.append(s1.p)
        
        return unsafeArea
    }
    
    static func debugIntersect(polyA a: [FixVec], polyB b: [FixVec]) -> Convex {
        let bndA = Boundary(points: a)
        let bndB = Boundary(points: b)
        let pins = Self.find(polyA: a, polyB: b, bndA: bndA, bndB: bndB)
        return Self.debugIntersect(polyA: a, polyB: b, pins: pins, bndA: bndA, bndB: bndB)
    }
    
    static func debugIntersect(polyA a: [FixVec], polyB b: [FixVec], pins: [Pin], bndA: Boundary, bndB: Boundary) -> Convex {
        guard pins.count > 1 else {
            if bndA.isOverlap(bndB) {
                return Convex(centroid: b.centroid, path: b)
            } else if bndB.isOverlap(bndA) {
                return Convex(centroid: a.centroid, path: a)
            } else {
                return .empty
            }
        }
        var points = [FixVec]()
        
        let p0 = pins.findFirst
        var p1 = p0
        repeat {
            let p2 = pins.findNext(current: p1, last: p0)
            if p1.isEndInto {
                points.directJoin(s0: p1.a, s1: p2.a, points: a)
            } else {
                points.directJoin(s0: p1.b, s1: p2.b, points: b)
            }

            p1 = p2
        } while p1.i != p0.i

        assert(points.count == Set(points).count)
        
        return Convex(centroid: points.centroid, path: points)
    }
    
}

public struct ABResult {
    public let a: [FixVec]
    public let b: [FixVec]
    public let unsafeArea: FixFloat
}
    
#endif
