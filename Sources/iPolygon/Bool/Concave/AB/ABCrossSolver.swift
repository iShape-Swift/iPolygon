//
//  ABCrossSolver.swift
//  
//
//  Created by Nail Sharipov on 23.06.2023.
//

import iFixFloat

private typealias ShapeId = Int

private extension ShapeId {
    static let a = 0
    static let b = 1
}

public enum ABLayout {
    case overlap
    case aInB
    case bInA
    case apart
    case aEqB
}

public struct ABCross {
    
    public let layout: ABLayout
    public let navigator: ABPinNavigator
    
    init(layout: ABLayout, navigator: ABPinNavigator) {
        self.layout = layout
        self.navigator = navigator
    }
}

public struct ABCrossSolver {
    
    public init() { }
    
    public func safeCross(pathA: [FixVec], pathB: [FixVec]) -> ABCross {
        let cleanA = pathA.fix().maxAreaPath
        let cleanB = pathB.fix().maxAreaPath
        
        let bndA = Boundary(points: cleanA)
        let bndB = Boundary(points: cleanB)
        
        return self.cross(pathA: cleanA, pathB: cleanB, bndA: bndA, bndB: bndB)
    }
    
    public func cross(pathA: [FixVec], pathB: [FixVec], bndA: Boundary, bndB: Boundary) -> ABCross {
        // at this time pathA and pathB must be correct!

        if bndA == bndB && pathA.count == pathB.count {
            // looks like a == b
            if pathA.isEqual(pathB) {
                return ABCross(layout: .aEqB, navigator: .empty)
            }
        }
        
        guard bndA.isCollide(bndB) else {
            return ABCross(layout: .apart, navigator: .empty)
        }

        let aEdges = pathA.filterEdges(shapeId: ShapeId.a, bnd: bndB)

        guard !aEdges.isEmpty else {
            return ABCross(layout: .apart, navigator: .empty)
        }
        
        let bEdges = pathB.filterEdges(shapeId: ShapeId.b, bnd: bndA)

        guard !bEdges.isEmpty else {
            return ABCross(layout: .apart, navigator: .empty)
        }
        
        let pins = self.intersect(edges: aEdges + bEdges)

        guard pins.count < 2 else {
            return ABCross(layout: .overlap, navigator: ABPinNavigator(pathA: pathA, pathB: pathB, pins: pins))
        }
        
        let eNavigator = ABPinNavigator(pins: pins)
        
        let anyA: FixVec
        let anyB: FixVec
        if pins.isEmpty {
            anyA = pathA[0]
            anyB = pathB[0]
        } else {
            let exPin = pins[0].p
            anyA = pathA.anyPoint(exclude: exPin)
            anyB = pathB.anyPoint(exclude: exPin)
        }
        
        if pathB.isContain(point: anyA) {
            return ABCross(layout: .aInB, navigator: eNavigator)
        }

        if pathA.isContain(point: anyB) {
            return ABCross(layout: .bInA, navigator: eNavigator)
        }

        return ABCross(layout: .apart, navigator: eNavigator)
    }
    
    private func intersect(edges: [ABEdge]) -> [Pin] {
        var queue = edges.sorted(by: { $0.e0.bitPack > $1.e0.bitPack })
        
        var listA = [ABEdge]()
        listA.reserveCapacity(8)
        
        var listB = [ABEdge]()
        listB.reserveCapacity(8)
        
        var pins = [Pin]()

    queueLoop:
        while !queue.isEmpty {
            
            // get edge with the smallest e0
            let thisEdge = queue.removeLast()
            
            let scanList: [ABEdge]
            if thisEdge.id == ShapeId.a {
                listB.removeAllE1(before: thisEdge.e0.bitPack)
                scanList = listB
            } else {
                listA.removeAllE1(before: thisEdge.e0.bitPack)
                scanList = listA
            }
            
            // try to cross with the scan list
            for scanIndex in 0..<scanList.count {
                
                let scanEdge = scanList[scanIndex]
                
                let cr = thisEdge.cross(scanEdge)
                
                switch cr.type {
                case .not_cross:
                    break
                case .common_end:
                    pins.appendUniq(e0: thisEdge, e1: scanEdge, p: cr.point)
                case .pure:
                    let cross = cr.point
                    
                    // devide edges

                    let thisLt = ABEdge(parent: thisEdge, e0: thisEdge.e0, e1: cross)
                    let thisRt = ABEdge(parent: thisEdge, e0: cross, e1: thisEdge.e1)
                    
                    let scanLt = ABEdge(parent: scanEdge, e0: scanEdge.e0, e1: cross)
                    let scanRt = ABEdge(parent: scanEdge, e0: cross, e1: scanEdge.e1)

                    queue.addE0(edge: thisLt)
                    queue.addE0(edge: thisRt)
                    queue.addE0(edge: scanRt)

                    if scanLt.id == ShapeId.a {
                        listA[scanIndex] = scanLt
                    } else {
                        listB[scanIndex] = scanLt
                    }
                    
                    continue queueLoop
                case .end_b:
                    let cross = cr.point

                    // devide this edge
                    
                    let thisLt = ABEdge(parent: thisEdge, e0: thisEdge.e0, e1: cross)
                    let thisRt = ABEdge(parent: thisEdge, e0: cross, e1: thisEdge.e1)

                    queue.addE0(edge: thisLt)
                    queue.addE0(edge: thisRt)

                    continue queueLoop
                case .end_a:
                    let cross = cr.point

                    // devide scan edge
                    
                    let scanLt = ABEdge(parent: scanEdge, e0: scanEdge.e0, e1: cross)
                    let scanRt = ABEdge(parent: scanEdge, e0: cross, e1: scanEdge.e1)

                    queue.addE0(edge: thisEdge) // put it back!
                    queue.addE0(edge: scanRt)
                    
                    if scanLt.id == ShapeId.a {
                        listA[scanIndex] = scanLt
                    } else {
                        listB[scanIndex] = scanLt
                    }
                    
                    continue queueLoop
                }
                
            } // for scanList
            
            // no intersections, add to scan
            if thisEdge.id == ShapeId.a {
                listA.addE0(edge: thisEdge)
            } else {
                listB.addE0(edge: thisEdge)
            }
        } // while queue
        
        if !pins.isEmpty {
            pins.sort(by: { $0.mA < $1.mA })
            for i in 0..<pins.count {
                pins[i] = Pin(i: i, pin: pins[i])
            }
        }

        return pins
    }
}

private extension Array where Element == FixVec {
    
    func filterEdges(shapeId: Int, bnd: Boundary) -> [ABEdge] {
        let last = self.count - 1
        var p0 = IndexPoint(index: last, point: self[last])
        
        var edges = [ABEdge]()

        for i in 0..<self.count {
            let p1 = IndexPoint(index: i, point: self[i])
            
            let eBnd = Boundary(p0: p0.point, p1: p1.point)
            
            if eBnd.isCollide(bnd) {
                let e = ABEdge(id: shapeId, a: p0, b: p1)
                edges.append(e)
            }
            p0 = p1
        }
        
        return edges
    }
    
    func anyPoint(exclude: FixVec) -> FixVec {
        let a = self[0]
        if a != exclude {
            return a
        } else {
            return self[1]
        }
    }
}

private extension Pin {
    
    init(e0: ABEdge, e1: ABEdge, p: FixVec) {
        i = 0
        self.p = p
        if e0.id == ShapeId.a {
            mA = e0.miliStone(p)
            mB = e1.miliStone(p)
        } else {
            mB = e0.miliStone(p)
            mA = e1.miliStone(p)
        }
    }
    
}

private extension Array where Element == Pin {
    
    mutating func appendUniq(e0: ABEdge, e1: ABEdge, p: FixVec) {
        for pin in self {
            if pin.p == p {
                return
            }
        }
        
        self.append(Pin(e0: e0, e1: e1, p: p))
    }
    
}
