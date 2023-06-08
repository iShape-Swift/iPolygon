//
//  Triangle.swift
//  
//
//  Created by Nail Sharipov on 02.06.2023.
//

import iFixFloat

public struct Triangle {

    @inlinable
    static func areaTwo(p0: FixVec, p1: FixVec, p2: FixVec) -> FixFloat {
        (p1 - p0).unsafeCrossProduct(p1 - p2)
    }
    
    @inlinable
    static func area(p0: FixVec, p1: FixVec, p2: FixVec) -> FixFloat {
        areaTwo(p0: p0, p1: p1, p2: p2) / 2
    }
    
    @inlinable
    static func fixArea(p0: FixVec, p1: FixVec, p2: FixVec) -> FixFloat {
        (p1 - p0).crossProduct(p1 - p2) / 2
    }
    
    @inlinable
    static func isClockwise(p0: FixVec, p1: FixVec, p2: FixVec) -> Bool {
        areaTwo(p0: p0, p1: p1, p2: p2) > 0
    }

    @inlinable
    static func isCW_or_Line(p0: FixVec, p1: FixVec, p2: FixVec) -> Bool {
        areaTwo(p0: p0, p1: p1, p2: p2) >= 0
    }
    
    @inlinable
    static func isNotLine(p0: FixVec, p1: FixVec, p2: FixVec) -> Bool {
        areaTwo(p0: p0, p1: p1, p2: p2) != 0
    }
    
    @inlinable
    static func isContain(p: FixVec, p0: FixVec, p1: FixVec, p2: FixVec) -> Bool {
        let q0 = (p - p1).unsafeCrossProduct(p0 - p1)
        let q1 = (p - p2).unsafeCrossProduct(p1 - p2)
        let q2 = (p - p0).unsafeCrossProduct(p2 - p0)
        
        let has_neg = q0 < 0 || q1 < 0 || q2 < 0
        let has_pos = q0 > 0 || q1 > 0 || q2 > 0
        
        return !(has_neg && has_pos)
    }
    
    @inlinable
    static func isNotContain(p: FixVec, p0: FixVec, p1: FixVec, p2: FixVec) -> Bool {
        let q0 = (p - p1).unsafeCrossProduct(p0 - p1)
        let q1 = (p - p2).unsafeCrossProduct(p1 - p2)
        let q2 = (p - p0).unsafeCrossProduct(p2 - p0)
        
        let has_neg = q0 <= 0 || q1 <= 0 || q2 <= 0
        let has_pos = q0 >= 0 || q1 >= 0 || q2 >= 0
        
        return has_neg && has_pos
    }
}
