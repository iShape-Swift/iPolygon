//
//  ABEdge.swift
//  
//
//  Created by Nail Sharipov on 23.06.2023.
//

import iFixFloat

struct ABEdge {

    static let empty = ABEdge(shapeId: -1, a: .zero, b: .zero)
    
    let shapeId: Int
    
    let p0: IndexPoint
    let p1: IndexPoint
    
    // start < end
    let e0: FixVec  // start
    let e1: FixVec  // end
    
    let isDirect: Bool

//    init(shapeId: Int, start: FixVec, end: FixVec, p0: IndexPoint, p1: IndexPoint) {
//        self.shapeId = shapeId
//        self.st = start
//        self.ed = end
//        self.p0 = p0
//        self.p1 = p1
//        self.isDirect = true
//    }
//
    init(parent: ABEdge, e0: FixVec, e1: FixVec) {
        self.shapeId = parent.shapeId
        self.e0 = e0
        self.e1 = e1
        self.p0 = parent.p0
        self.p1 = parent.p1
        self.isDirect = parent.isDirect
    }
//
//    init(parent: ABEdge, a: FixVec, b: FixVec) {
//        if a.bitPack < b.bitPack {
//            self.st = a
//            self.ed = b
//        } else {
//            self.st = b
//            self.ed = a
//        }
//        self.shapeId = parent.shapeId
//        self.p0 = parent.p0
//        self.p1 = parent.p1
//    }
    
    init(shapeId: Int, a: IndexPoint, b: IndexPoint) {
        isDirect = a.point.bitPack < b.point.bitPack
        if isDirect {
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
        self.shapeId = shapeId
    }

    @usableFromInline
    struct CrossResult {
        
        @usableFromInline
        let type: CrossType
        
        @usableFromInline
        let pin: Pin
        
        @inlinable
        init(type: CrossType, pin: Pin) {
            self.type = type
            self.pin = pin
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
    func cross(_ other: ABEdge) -> CrossResult {
        let a0: FixVec
        let a1: FixVec
        if self.isDirect {
            a0 = e0
            a1 = e1
        } else {
            a0 = e1
            a1 = e0
        }

        let b0: FixVec
        let b1: FixVec
        if self.isDirect {
            b0 = other.e0
            b1 = other.e1
        } else {
            b0 = other.e1
            b1 = other.e0
        }
        
        let d0 = Triangle.clockDirection(p0: a0, p1: b0, p2: b1)
        let d1 = Triangle.clockDirection(p0: a1, p1: b0, p2: b1)
        let d2 = Triangle.clockDirection(p0: a0, p1: a1, p2: b0)
        let d3 = Triangle.clockDirection(p0: a0, p1: a1, p2: b1)

        if d0 == 0 || d1 == 0 || d2 == 0 || d3 == 0 {
            if d0 == 0 && d1 == 0 && d2 == 0 && d3 == 0 {
                return .init(type: .same_line, pin: .zero)
            }
            if d0 == 0 {
                if d2 == 0 || d3 == 0 {
                    if d2 == 0 {
                        return CrossResult(
                            type: .end_a0_b0,
                            pin: Pin(
                                p: a0,
                                mA: p0.mileStone,
                                mB: other.p0.mileStone
                            )
                        )
                    } else {
                        return CrossResult(
                            type: .end_a0_b1,
                            pin: Pin(
                                p: a0,
                                mA: p0.mileStone,
                                mB: other.p1.mileStone
                            )
                        )
                    }
                } else if d2 != d3 {
                    return CrossResult(
                        type: .end_a0,
                        pin: Pin(
                            p: a0,
                            mA: p0.mileStone,
                            mB: other.p0.mileStone(point: a0)
                        )
                    )
                } else {
                    return CrossResult(type: .not_cross, pin: .zero)
                }
            }
            if d1 == 0 {
                if d2 == 0 || d3 == 0 {
                    if d2 == 0 {
                        return CrossResult(
                            type: .end_a1_b0,
                            pin: Pin(
                                p: a1,
                                mA: p1.mileStone,
                                mB: other.p0.mileStone
                            )
                        )
                    } else {
                        return CrossResult(
                            type: .end_a1_b1,
                            pin: Pin(
                                p: a1,
                                mA: p1.mileStone,
                                mB: other.p1.mileStone
                            )
                        )
                    }
                } else if d2 != d3 {
                    return CrossResult(
                        type: .end_a1,
                        pin: Pin(
                            p: a1,
                            mA: p1.mileStone,
                            mB: other.p0.mileStone(point: a1)
                        )
                    )
                } else {
                    return CrossResult(type: .not_cross, pin: .zero)
                }
            }
            if d0 != d1 {
                if d2 == 0 {
                    return CrossResult(
                        type: .end_b0,
                        pin: Pin(
                            p: b0,
                            mA: p0.mileStone(point: b0),
                            mB: other.p0.mileStone
                        )
                    )
                } else {
                    return CrossResult(
                        type: .end_b1,
                        pin: Pin(
                            p: b1,
                            mA: p0.mileStone(point: b1),
                            mB: other.p1.mileStone
                        )
                    )
                }
            } else {
                return CrossResult(type: .not_cross, pin: .zero)
            }
        } else if d0 != d1 && d2 != d3 {
            let cross = self.crossPoint(a0: a0, a1: a1, b0: b0, b1: b1)

            // still can be ends (watch case union 44)
            let isA0 = a0 == cross
            let isA1 = a1 == cross
            let isB0 = b0 == cross
            let isB1 = b1 == cross
            
            let mA: MileStone
            let mB: MileStone
            
            let type: CrossType
            
            if !(isA0 || isA1 || isB0 || isB1) {
                type = .pure
                mA = p0.mileStone(point: cross)
                mB = other.p0.mileStone(point: cross)
            } else if isA0 && isB0 {
                type = .end_a0_b0
                mA = p0.mileStone
                mB = other.p0.mileStone
            } else if isA0 && isB1 {
                type = .end_a0_b1
                mA = p0.mileStone
                mB = other.p1.mileStone
            } else if isA1 && isB0 {
                type = .end_a1_b0
                mA = p1.mileStone
                mB = other.p0.mileStone
            } else if isA1 && isB1 {
                type = .end_a1_b1
                mA = p1.mileStone
                mB = other.p1.mileStone
            } else if isA0 {
                type = .end_a0
                mA = p0.mileStone
                mB = other.p0.mileStone(point: cross)
            } else if isA1 {
                type = .end_a1
                mA = p1.mileStone
                mB = other.p0.mileStone(point: cross)
            } else if isB0 {
                type = .end_b0
                mA = p0.mileStone(point: cross)
                mB = other.p0.mileStone
            } else {
                type = .end_b1
                mA = p0.mileStone(point: cross)
                mB = other.p1.mileStone
            }
            
            return CrossResult(
                type: type,
                pin: Pin(
                    p: cross,
                    mA: mA,
                    mB: mB
                )
            )
        } else {
            return CrossResult(type: .not_cross, pin: .zero)
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
