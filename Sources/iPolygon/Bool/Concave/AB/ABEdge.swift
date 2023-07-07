//
//  ABEdge.swift
//  
//
//  Created by Nail Sharipov on 23.06.2023.
//

import iFixFloat

struct ABEdge {

    static let empty = ABEdge(id: -1, a: .zero, b: .zero)
    
    let id: Int
    
    let p0: IndexPoint
    let p1: IndexPoint
    
    // start < end
    let e0: FixVec  // start
    let e1: FixVec  // end

    @inlinable
    init(parent: ABEdge, e0: FixVec, e1: FixVec) {
        self.e0 = e0
        self.e1 = e1
        self.id = parent.id
        self.p0 = parent.p0
        self.p1 = parent.p1
    }

    @inlinable
    init(id: Int, a: IndexPoint, b: IndexPoint) {
        if a.point.bitPack < b.point.bitPack {
            self.p0 = a
            self.p1 = b
            self.e0 = a.point
            self.e1 = b.point
        } else {
            self.p0 = a
            self.p1 = b
            self.e1 = a.point
            self.e0 = b.point
        }
        self.id = id
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
        case not_cross          // no intersections or parallel
        case pure               // simple intersection with no overlaps or common points
        
        case end_a
        case end_b
        
        case common_end
    }
    
    @inlinable
    func cross(_ other: ABEdge) -> CrossResult {
        let a0 = e0
        let a1 = e1

        let b0 = other.e0
        let b1 = other.e1
        
        let d0 = Triangle.clockDirection(p0: a0, p1: b0, p2: b1)
        let d1 = Triangle.clockDirection(p0: a1, p1: b0, p2: b1)
        let d2 = Triangle.clockDirection(p0: a0, p1: a1, p2: b0)
        let d3 = Triangle.clockDirection(p0: a0, p1: a1, p2: b1)

        var p: FixVec = .zero
        var type: CrossType = .not_cross
        
        if d0 == 0 || d1 == 0 || d2 == 0 || d3 == 0 {
            if !(d0 == 0 && d1 == 0 && d2 == 0 && d3 == 0) {
                if d0 == 0 {
                    p = a0
                    if d2 == 0 || d3 == 0 {
                        type = .common_end
                    } else if d2 != d3 {
                        type = .end_a
                    }
                } else if d1 == 0 {
                    p = a1
                    if d2 == 0 || d3 == 0 {
                        type = .common_end
                    } else if d2 != d3 {
                        type = .end_a
                    }
                } else if d0 != d1 {
                    if d2 == 0 {
                        p = b0
                    } else {
                        p = b1
                    }
                    type = .end_b
                }
            }
        } else if d0 != d1 && d2 != d3 {
            p = self.crossPoint(a0: a0, a1: a1, b0: b0, b1: b1)

            // still can be ends
            let isA0 = a0 == p
            let isA1 = a1 == p
            let isB0 = b0 == p
            let isB1 = b1 == p
            
            if !(isA0 || isA1 || isB0 || isB1) {
                type = .pure
            } else if isA0 && isB0 || isA0 && isB1 || isA1 && isB0 || isA1 && isB1 {
                type = .common_end
            } else if isA0 || isA1 {
                type = .end_a
            } else if isB0 || isB1 {
                type = .end_b
            }
        }

        return CrossResult(type: type, point: p)
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

    @inlinable
    func miliStone(_ p: FixVec) -> MileStone {
        if p == p1.point {
            return MileStone(index: p1.index)
        } else if p == p0.point {
            return MileStone(index: p0.index)
        } else {
            return MileStone(index: p0.index, offset: p.sqrDistance(p0.point))
        }
    }

}
