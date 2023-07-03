//
//  ConvexOverlaySolver+Intersect.swift
//  
//
//  Created by Nail Sharipov on 22.05.2023.
//

import iFixFloat

public extension ConvexOverlaySolver {

    static func intersect(polyA a: [FixVec], polyB b: [FixVec], bndA: Boundary, bndB: Boundary) -> Centroid {
        let pins = Self.find(polyA: a, polyB: b, bndA: bndA, bndB: bndB)
        return Self.intersect(polyA: a, polyB: b, pins: pins, bndA: bndA, bndB: bndB)
    }
    
    static func intersect(polyA a: [FixVec], polyB b: [FixVec], pins: [Pin], bndA: Boundary, bndB: Boundary) -> Centroid {
        guard pins.count > 1 else {
            if bndA.isOverlap(bndB) {
                return b.centroid
            } else if bndB.isOverlap(bndA) {
                return a.centroid
            } else {
                return .zero
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
        
//        assert(points.count == Set(points).count)
        
        return points.centroid
    }
    
}


extension Array where Element == Pin {
    
    var findFirst: Pin {
        for p in self {
            switch p.type {
            case .empty, .into_empty, .out_empty: // can be removed
                continue
            default:
                return p
            }
        }
        
        for p in self where p.type != .empty {
            return p
        }
        
        return .zero
    }
    
    func findNext(current: Pin, last: Pin) -> Pin {
        let isInto = current.isEndInto
        var next = self.next(pin: current)
        while next.mA != last.mA {
            if isInto {
                let isOut = next.isEndOut
                if isOut {
                    return next
                }
            } else {
                let isInto = next.isEndInto
                if isInto {
                    return next
                }
            }
            next = self.next(pin: next)
        }
        
        return last
    }
    
}

extension Pin {
    
    var isEndInto: Bool {
        switch self.type {
        case .into, .empty_into, .out_into:
            return true
        default:
            return false
        }
    }

    var isEndOut: Bool {
        switch self.type {
        case .out, .empty_out, .into_out:
            return true
        default:
            return false
        }
    }
    
}

extension Array where Element == FixVec {
    
    mutating func directJoin(s0: PointStone, s1: PointStone, points: [FixVec]) {
        self.append(s0.p)

        if s0.m < s1.m {
            // example from 3 to 6

            var i = s0.m.index + 1
            
            let last = s1.m.offset == 0 ? s1.m.index : s1.m.index + 1
            
            while i < last {
                self.append(points[i])
                i += 1
            }
        } else {
            // example from 5 to 2
            var i = s0.m.index + 1
            
            while i < points.count {
                self.append(points[i])
                i += 1
            }

            i = 0
            let last = s1.m.offset == 0 ? s1.m.index : s1.m.index + 1
            
            while i < last {
                self.append(points[i])
                i += 1
            }
        }
    }
    
}
