//
//  Solver+Brute.swift
//  
//
//  Created by Nail Sharipov on 20.05.2023.
//

import iFixFloat

extension ConvexCrossSolver {
    
    static func bruteIntersect(polyA: [FixVec], polyB: [FixVec], bndA: Boundary, bndB: Boundary) -> [Pin] {
        let listB = polyB.edges(filter: bndA)
        
        var pins = [Pin]()

        var i0 = polyA.count - 1
        var a0 = polyA[i0]
        var i1 = 0
        for a1 in polyA {
            let bd = Boundary(p0: a0, p1: a1)
            if bd.isCollide(bndB) {
                let eA = Edge(p0: IndexPoint(index: i0, point: a0), p1: IndexPoint(index: i1, point: a1), bd: bd)
                for eB in listB {
                    let result = eA.cross(eB)
                    if result.isCross {
                        pins.append(result.pin)
                    }
                }
            }
            
            a0 = a1
            i0 = i1
            i1 += 1
        }
     
        guard pins.count > 1 else {
            return pins
        }
        
        pins.sort(by: { $0.mA < $1.mA })
        
        var result = [Pin]()
        var p0 = pins[0]
        result.append(p0)
        for i in 1..<pins.count {
            var pi = pins[i]
            if p0.mA != pi.mA {
                pi.i = result.count
                result.append(pi)
            }
            p0 = pi
        }
        
        return result
    }
   
}

private struct Edge {

    struct CrossResult {
        let isCross: Bool
        let pin: Pin
    }

    let p0: IndexPoint
    let p1: IndexPoint
    let bd: Boundary

    func cross(_ other: Edge) -> CrossResult {
        guard self.bd.isCollide(other.bd) else {
            return .init(isCross: false, pin: .zero)
        }

        let a0 = self.p0.point
        let a1 = self.p1.point

        let b0 = other.p0.point
        let b1 = other.p1.point
        
        let d0 = Triangle.clockDirection(p0: a0, p1: b0, p2: b1)
        let d1 = Triangle.clockDirection(p0: a1, p1: b0, p2: b1)
        let d2 = Triangle.clockDirection(p0: a0, p1: a1, p2: b0)
        let d3 = Triangle.clockDirection(p0: a0, p1: a1, p2: b1)

        if d0 == 0 || d1 == 0 || d2 == 0 || d3 == 0 {
            if d0 == 0 && d1 == 0 && d2 == 0 && d3 == 0 {
                return .init(isCross: false, pin: .zero)
            }
            if d0 == 0 {
                if d2 == 0 || d3 == 0 {
                    if d2 == 0 {
                        // a0_b0
                        return .init(
                            isCross: true,
                            pin: .init(
                                p: a0,
                                mA: p0.mileStone,
                                mB: other.p0.mileStone
                            ))
                    } else {
                        // a0_b1
                        return .init(
                            isCross: true,
                            pin: .init(
                                p: a0,
                                mA: p0.mileStone,
                                mB: other.p1.mileStone
                            ))
                    }
                } else if d2 != d3 {
                    // a0
                    return .init(
                        isCross: true,
                        pin: .init(
                            p: a0,
                            mA: p0.mileStone,
                            mB: other.p0.mileStone(point: a0)
                        ))
                } else {
                    return .init(isCross: false, pin: .zero)
                }
            }
            if d1 == 0 {
                if d2 == 0 || d3 == 0 {
                    if d2 == 0 {
                        // a1_b0
                        return .init(
                            isCross: true,
                            pin: .init(
                                p: a1,
                                mA: p1.mileStone,
                                mB: other.p0.mileStone
                            ))
                    } else {
                        // a1_b1
                        return .init(
                            isCross: true,
                            pin: .init(
                                p: a1,
                                mA: p1.mileStone,
                                mB: other.p1.mileStone
                            ))
                    }
                } else if d2 != d3 {
                    // a1
                    return .init(
                        isCross: true,
                        pin: .init(
                            p: a1,
                            mA: p1.mileStone,
                            mB: other.p0.mileStone(point: a1)
                        ))
                } else {
                    return .init(isCross: false, pin: .zero)
                }
            }
            if d0 != d1 {
                if d2 == 0 {
                    // b0
                    return .init(
                        isCross: true,
                        pin: .init(
                            p: b0,
                            mA: p0.mileStone(point: b0),
                            mB: other.p0.mileStone
                        ))
                } else {
                    // b1
                    return .init(
                        isCross: true,
                        pin: .init(
                            p: b1,
                            mA: p0.mileStone(point: b1),
                            mB: other.p1.mileStone
                        ))
                }
            } else {
                return .init(isCross: false, pin: .zero)
            }
        } else if d0 != d1 && d2 != d3 {
            let cross = Self.crossPoint(a0: a0, a1: a1, b0: b0, b1: b1)

            // still can be ends
            let isA0 = a0 == cross
            let isA1 = a1 == cross
            let isB0 = b0 == cross
            let isB1 = b1 == cross
            
            let mA: MileStone
            let mB: MileStone

            if !(isA0 || isA1 || isB0 || isB1) {
                mA = p0.mileStone(point: cross)
                mB = other.p0.mileStone(point: cross)
            } else if isA0 && isB0 {
                // a0_b0
                mA = p0.mileStone
                mB = other.p0.mileStone
            } else if isA0 && isB1 {
                // a0_b1
                mA = p0.mileStone
                mB = other.p1.mileStone
            } else if isA1 && isB0 {
                // a1_b0
                mA = p1.mileStone
                mB = other.p0.mileStone
            } else if isA1 && isB1 {
                // a1_b1
                mA = p1.mileStone
                mB = other.p1.mileStone
            } else if isA0 {
                // a0
                mA = p0.mileStone
                mB = other.p0.mileStone(point: cross)
            } else if isA1 {
                // a1
                mA = p1.mileStone
                mB = other.p0.mileStone(point: cross)
            } else if isB0 {
                // b0
                mA = p0.mileStone(point: cross)
                mB = other.p0.mileStone
            } else {
                // b1
                mA = p0.mileStone(point: cross)
                mB = other.p1.mileStone
            }
            
            return .init(
                isCross: true,
                pin: .init(
                    p: cross,
                    mA: mA,
                    mB: mB
                ))
        } else {
            return .init(isCross: false, pin: .zero)
        }
    }

    private static func crossPoint(a0: FixVec, a1: FixVec, b0: FixVec, b1: FixVec) -> FixVec {
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

private extension Array where Element == FixVec {
    
    func edges(filter: Boundary) -> [Edge] {
        var edges = [Edge]()
        edges.reserveCapacity(count)
        
        var i0 = count - 1
        var i1 = 0
        var a0 = self[i0]
        for a1 in self {
            let bd = Boundary(p0: a0, p1: a1)
            if bd.isCollide(filter) {
                edges.append(Edge(p0: IndexPoint(index: i0, point: a0), p1: .init(index: i1, point: a1), bd: bd))
            }
            a0 = a1
            i0 = i1
            i1 += 1
        }
        
        return edges
    }
    
}
