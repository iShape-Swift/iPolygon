//
//  Convex+isConvex.swift
//  
//
//  Created by Nail Sharipov on 17.05.2023.
//

import iFixFloat

public enum ConvexTest {
    
    case convex
    case nonConvex
    case degenerate
}

public extension Array where Element == FixVec {
    
    @inlinable
    var mostLeft: Int {
        let n = self.count
        let p1 = self[1].bitPack
        let p0 = self[0].bitPack
        if p1 > p0 {
            // search back
            var p = p0
            var i = 0
            var j = i.prev(n)
            var pi = self[j].bitPack
            while pi < p {
                p = pi
                i = j
                j = j.prev(n)
                pi = self[j].bitPack
            }
            return i
        } else {
            // search forward
            var p = p1
            var i = 1
            var j = i.next(n)
            var pi = self[j].bitPack
            while pi < p {
                p = pi
                i = j
                j = j.next(n)
                pi = self[j].bitPack
            }
            return i
        }
    }
    
    var isConvex: ConvexTest {
        let n = self.count
        var p0 = self[n - 2]
        var p1 = self[n - 1]

        var hasDegenerate = false
        
        for p2 in self {
            let result = Self.orientation(a: p0, b: p1, c: p2)
            if result < 0 {
                return .nonConvex
            }
            
            hasDegenerate = hasDegenerate || result == 0
            
            p0 = p1
            p1 = p2
        }
        
        if hasDegenerate {
            return .degenerate
        }
        
        return .convex
    }

    private static func orientation(a: FixVec, b: FixVec, c: FixVec) -> FixFloat {
        (b.y - a.y) * (c.x - b.x) - (b.x - a.x) * (c.y - b.y)
    }

    private static func isTriangleContain(a: FixVec, b: FixVec, c: FixVec, p: FixVec) -> Bool {
        let s0 = orientation(a: a, b: b, c: p)
        let s1 = orientation(a: b, b: c, c: p)
        let s2 = orientation(a: c, b: a, c: p)

        return s0 >= 0 && s1 >= 0 && s2 >= 0
    }
}
