//
//  ABCrossSolver.swift
//  
//
//  Created by Nail Sharipov on 23.06.2023.
//

import iFixFloat

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

private struct DivideResult {
    let ltPart: ABEdge
    let rtPart: ABEdge
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

        let aEdges = pathA.filterEdges(startIndex: 0, shapeId: .a, bnd: bndB)

        guard !aEdges.isEmpty else {
            return ABCross(layout: .apart, navigator: .empty)
        }
        
        let bEdges = pathB.filterEdges(startIndex: aEdges.count, shapeId: .b, bnd: bndA)

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
        
        var idGen = ABIdGenerator(counter: edges.count)
        
        var scanBank = ABScanBank()

        var pins = [Pin]()

    queueLoop:
        while !queue.isEmpty {
            
            // get edge with the smallest e0
            let thisEdge = queue.removeLast()
            
            let thisShapeId = thisEdge.id.shapeId
            
            let scanList = scanBank.scanList(shapeId: thisShapeId, filter: thisEdge.e0.bitPack)
            
            // try to cross with the scan list
            for scanEdge in scanList {
                
                let cr = thisEdge.cross(scanEdge)
                
                switch cr.type {
                case .not_cross:
                    break
                case .common_end:
                    pins.appendUniq(e0: thisEdge, e1: scanEdge, p: cr.point)
                case .pure:
                    let cross = cr.point
                    
                    pins.appendUniq(e0: thisEdge, e1: scanEdge, p: cr.point)
                    
                    // devide edges

                    let thisEdges = self.devide(
                        edge: thisEdge,
                        cross: cross,
                        ltId: idGen.next(shapeId: thisShapeId),
                        rtId: idGen.next(shapeId: thisShapeId)
                    )

                    let scanShapeId = scanEdge.id.shapeId
                    
                    let scanEdges = self.devide(
                        edge: scanEdge,
                        cross: cross,
                        ltId: idGen.next(shapeId: scanShapeId),
                        rtId: idGen.next(shapeId: scanShapeId)
                    )

                    queue.addE0(edge: thisEdges.ltPart)
                    queue.addE0(edge: thisEdges.rtPart)
                    queue.addE0(edge: scanEdges.rtPart)

                    scanBank.add(edge: scanEdges.ltPart)
                    
                    continue queueLoop
                case .end_b:
                    let cross = cr.point
                    
                    pins.appendUniq(e0: thisEdge, e1: scanEdge, p: cr.point)

                    let thisEdges = self.devide(
                        edge: thisEdge,
                        cross: cross,
                        ltId: idGen.next(shapeId: thisShapeId),
                        rtId: idGen.next(shapeId: thisShapeId)
                    )

                    queue.addE0(edge: thisEdges.ltPart)
                    queue.addE0(edge: thisEdges.rtPart)

                    continue queueLoop
                case .end_a:
                    let cross = cr.point
                    
                    pins.appendUniq(e0: thisEdge, e1: scanEdge, p: cr.point)
                    
                    // devide other(scan) edge

                    let scanShapeId = scanEdge.id.shapeId
                    
                    let scanEdges = self.devide(
                        edge: scanEdge,
                        cross: cross,
                        ltId: idGen.next(shapeId: scanShapeId),
                        rtId: idGen.next(shapeId: scanShapeId)
                    )

                    queue.addE0(edge: scanEdges.rtPart)
                    scanBank.add(edge: scanEdges.ltPart)
                    
                    continue queueLoop
                }
                
            } // for scanList
            
            // no intersections, add to scan
            
            scanBank.add(edge: thisEdge)

        } // while queue
        
        if !pins.isEmpty {
            pins.sort(by: { $0.mA < $1.mA })
            for i in 0..<pins.count {
                pins[i] = Pin(i: i, pin: pins[i])
            }
        }

        return pins
    }
    
    private func devide(edge: ABEdge, cross: FixVec, ltId: Int, rtId: Int) -> DivideResult {
        let ltPart = ABEdge(id: ltId, parent: edge, e0: edge.e0, e1: cross)
        let rtPart = ABEdge(id: rtId, parent: edge, e0: cross, e1: edge.e1)

        return DivideResult(
            ltPart: ltPart,
            rtPart: rtPart
        )
    }
}

private extension Array where Element == FixVec {
    
    func filterEdges(startIndex: Int, shapeId: ABShapeId, bnd: Boundary) -> [ABEdge] {
        var idGen = ABIdGenerator(counter: startIndex)
        
        let last = self.count - 1
        var p0 = IndexPoint(index: last, point: self[last])
        
        var edges = [ABEdge]()

        for i in 0..<self.count {
            let p1 = IndexPoint(index: i, point: self[i])
            
            let eBnd = Boundary(p0: p0.point, p1: p1.point)
            
            if eBnd.isCollide(bnd) {
                let id = idGen.next(shapeId: shapeId)
                let e = ABEdge(id: id, a: p0, b: p1)
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
        if e0.id.shapeId == .a {
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
