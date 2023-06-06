//
//  Triangle.swift
//  
//
//  Created by Nail Sharipov on 02.06.2023.
//

import iFixFloat

public struct Triangle {
    
    @inlinable
    static func area(p0: FixVec, p1: FixVec, p2: FixVec) -> FixFloat {
        let e0 = p1 - p0
        let e1 = p1 - p2

        return e0.unsafeCrossProduct(e1) / 2
    }
    
    @inlinable
    static func fixArea(p0: FixVec, p1: FixVec, p2: FixVec) -> FixFloat {
        let e0 = p1 - p0
        let e1 = p1 - p2

        return e0.crossProduct(e1) / 2
    }
    
    @inlinable
    static func isClockwise(p0: FixVec, p1: FixVec, p2: FixVec) -> Bool {
        let e0 = p1 - p0
        let e1 = p1 - p2

        return e0.unsafeCrossProduct(e1) > 0
    }
    
    @inlinable
    static func isCounterClockwise(p0: FixVec, p1: FixVec, p2: FixVec) -> Bool {
        let e0 = p1 - p0
        let e1 = p1 - p2

        return e0.unsafeCrossProduct(e1) < 0
    }
}
