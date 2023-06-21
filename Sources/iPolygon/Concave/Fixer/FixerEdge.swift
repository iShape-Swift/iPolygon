//
//  FixerEdge.swift
//  
//
//  Created by Nail Sharipov on 13.06.2023.
//

import iFixFloat

@usableFromInline
struct FixerEdge {

    static let zero = FixerEdge(a: .zero, b: .zero)
    
    // a < b

    @usableFromInline
    let a: FixVec
    
    @usableFromInline
    let b: FixVec
    
    @inlinable
    init(a: FixVec, b: FixVec) {
        self.a = a
        self.b = b
    }
    
    @usableFromInline
    struct CrossResult {
        
        @usableFromInline
        let type: CrossType
        
        @usableFromInline
        let point: FixVec
        
        @inlinable
        init(type: CrossType, point: FixVec) {
            self.type = type
            self.point = point
        }
    }
    
    @usableFromInline
    enum CrossType {
        case not_cross          // no intersections
        case pure               // simple intersection with no overlaps or common points
        case same_line          // same line
        
        case end_a0
        case end_a1
        case end_b0
        case end_b1
        case end_a0_b0
        case end_a0_b1
        case end_a1_b0
        case end_a1_b1
        
    }
    
    @inlinable
    func cross(other: FixerEdge) -> CrossResult {
        let a0 = self.a
        let a1 = self.b

        let b0 = other.a
        let b1 = other.b
        
        let d0 = Triangle.clockDirection(p0: a0, p1: b0, p2: b1)
        let d1 = Triangle.clockDirection(p0: a1, p1: b0, p2: b1)
        let d2 = Triangle.clockDirection(p0: a0, p1: a1, p2: b0)
        let d3 = Triangle.clockDirection(p0: a0, p1: a1, p2: b1)

        if d0 == 0 || d1 == 0 || d2 == 0 || d3 == 0 {
            if d0 == 0 && d1 == 0 && d2 == 0 && d3 == 0 {
                return .init(type: .same_line, point: .zero)
            }
            if d0 == 0 {
                if d2 == 0 || d3 == 0 {
                    if d2 == 0 {
                        return .init(type: .end_a0_b0, point: a0)
                    } else {
                        return .init(type: .end_a0_b1, point: a0)
                    }
                } else if d2 != d3 {
                    return .init(type: .end_a0, point: a0)
                } else {
                    return .init(type: .not_cross, point: .zero)
                }
            }
            if d1 == 0 {
                if d2 == 0 || d3 == 0 {
                    if d2 == 0 {
                        return .init(type: .end_a1_b0, point: a1)
                    } else {
                        return .init(type: .end_a1_b1, point: a1)
                    }
                } else if d2 != d3 {
                    return .init(type: .end_a1, point: a1)
                } else {
                    return .init(type: .not_cross, point: .zero)
                }
            }
            if d0 != d1 {
                if d2 == 0 {
                    return .init(type: .end_b0, point: b0)
                } else {
                    return .init(type: .end_b1, point: b1)
                }
            } else {
                return .init(type: .not_cross, point: .zero)
            }
        } else if d0 != d1 && d2 != d3 {
            let cross = self.crossPoint(a0: a0, a1: a1, b0: b0, b1: b1)

            // still can be ends (watch case union 44)
            let isA0 = a0 == cross
            let isA1 = a1 == cross
            let isB0 = b0 == cross
            let isB1 = b1 == cross
            
            let type: CrossType
            
            if !(isA0 || isA1 || isB0 || isB1) {
                type = .pure
            } else if isA0 && isB0 {
                type = .end_a0_b0
            } else if isA0 && isB1 {
                type = .end_a0_b1
            } else if isA1 && isB0 {
                type = .end_a1_b0
            } else if isA1 && isB1 {
                type = .end_a1_b1
            } else if isA0 {
                type = .end_a0
            } else if isA1 {
                type = .end_a1
            } else if isB0 {
                type = .end_b0
            } else {
                type = .end_b1
            }
            
            return .init(type: type, point: cross)
        } else {
            return .init(type: .not_cross, point: .zero)
        }
    }
    
    @inlinable
    func crossPoint(a0: FixVec, a1: FixVec, b0: FixVec, b1: FixVec) -> FixVec {
        let dxA = a0.x - a1.x
        let dyB = b0.y - b1.y
        let dyA = a0.y - a1.y
        let dxB = b0.x - b1.x

        let xyA = a0.x * a1.y - a0.y * a1.x
        let xyB = b0.x * b1.y - b0.y * b1.x
        
        let x = xyA * dxB - dxA * xyB
        let y = xyA * dyB - dyA * xyB

        let divider = dxA * dyB - dyA * dxB
        
        let cx = x / divider
        let cy = y / divider
        
        return FixVec(cx, cy)
    }
}
