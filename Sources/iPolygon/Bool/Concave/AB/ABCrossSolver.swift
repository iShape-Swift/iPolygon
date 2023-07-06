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
    let remEvent: SwipeEvent
    let addEvent: SwipeEvent
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

        let aEdges = pathA.filterEdges(shapeId: 0, bnd: bndB)

        guard !aEdges.isEmpty else {
            return ABCross(layout: .apart, navigator: .empty)
        }

        let bEdges = pathB.filterEdges(shapeId: 1, bnd: bndA)

        guard !bEdges.isEmpty else {
            return ABCross(layout: .apart, navigator: .empty)
        }
        
        let pins = self.intersect(aEdges: aEdges, bEdges: bEdges)

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
    
    private func intersect(aEdges: [ABEdge], bEdges: [ABEdge]) -> [Pin] {
        var edges = [ABEdge]()
        edges.append(contentsOf: aEdges)
        edges.append(contentsOf: bEdges)

        var evQueue = EventQueue(edges: edges)
        
        var scanList = [Int]()
        scanList.reserveCapacity(16)

        var pins = [Pin]()
        
        while evQueue.hasNext {
            
            let event = evQueue.next()

            switch event.action {
            case .add:
                
                var thisId = event.edgeId
                var thisEdge = edges[thisId]
                var newScanId = thisId
                
                // try to cross with the scan list
                var j = 0
                while j < scanList.count {
                    let otherId = scanList[j]
                    let otherEdge = edges[otherId]
                    
                    guard otherEdge.shapeId != thisEdge.shapeId else {
                        j += 1
                        continue
                    }
                    
                    let cr = thisEdge.cross(otherEdge)
                    
                    switch cr.type {
                    case .not_cross:
                        j += 1
                    case .common_end:
                        pins.appendUniq(e0: thisEdge, e1: otherEdge, p: cr.point)
                        
                        j += 1
                    case .pure:
                        let cross = cr.point
                        
                        pins.appendUniq(e0: thisEdge, e1: otherEdge, p: cr.point)
                        
                        // devide edges
                        
                        // for this edge
                        // create new left part (new edge id), put 'remove' event
                        // update right part (keep old edge id), put 'add' event
                        
                        let thisNewId = edges.count
                        let thisResult = self.devide(edge: thisEdge, id: thisId, cross: cross, nextId: thisNewId)
                        
                        edges.append(thisResult.ltPart)
                        thisEdge = thisResult.ltPart
                        edges[thisId] = thisResult.rtPart    // update old edge (right part)
                        thisId = thisNewId                      // we are now left part with new id

                        newScanId = thisNewId
                        
                        // for other(scan) edge
                        // create new left part (new edge id), put 'remove' event
                        // update right part (keep old edge id), put 'add' event
                        
                        let otherNewId = edges.count
                        let otherResult = self.devide(edge: otherEdge, id: otherId, cross: cross, nextId: otherNewId)
                        
                        edges.append(otherResult.ltPart)
                        edges[otherId] = otherResult.rtPart

                        scanList[j] = otherNewId
                        
                        // insert events

                        evQueue.add(events: [
                            thisResult.remEvent,
                            otherResult.remEvent,
                            thisResult.addEvent,
                            otherResult.addEvent
                        ], at: thisResult.remEvent.sort)

                        j += 1
                    case .end_b:
                        let cross = cr.point
                        
                        pins.appendUniq(e0: thisEdge, e1: otherEdge, p: cr.point)
                        
                        // devide this edge
                        
                        // create new left part (new edge id), put 'remove' event
                        // update right part (keep old edge id), put 'add' event
                        
                        let thisNewId = edges.count
                        let thisResult = self.devide(edge: thisEdge, id: thisId, cross: cross, nextId: thisNewId)
                        
                        thisEdge = thisResult.ltPart
                        edges.append(thisResult.ltPart)
                        edges[thisId] = thisResult.rtPart    // update old edge (right part)
                        thisId = thisNewId                      // we are now left part with new id
                        
                        newScanId = thisNewId
                        
                        evQueue.add(events: [
                            thisResult.remEvent,
                            thisResult.addEvent,
                        ], at: thisResult.remEvent.sort)

                        j += 1
                    case .end_a:
                        let cross = cr.point
                        
                        pins.appendUniq(e0: thisEdge, e1: otherEdge, p: cr.point)
                        
                        // devide other(scan) edge

                        // create new left part (new edge id), put 'remove' event
                        // update right part (keep old edge id), put 'add' event

                        let otherNewId = edges.count
                        let otherResult = self.devide(edge: otherEdge, id: otherId, cross: cross, nextId: otherNewId)
                        
                        edges.append(otherResult.ltPart)
                        edges[otherId] = otherResult.rtPart
                        
                        scanList[j] = otherNewId
                        
                        // insert events

                        evQueue.add(events: [
                            otherResult.remEvent,
                            otherResult.addEvent
                        ], at: otherResult.remEvent.sort)

                        j += 1
                    }
                } // while scanList
                
                scanList.append(newScanId)

            case .remove:
                // scan list is sorted
                if let index = scanList.firstIndex(of: event.edgeId) { // it must be one of the first elements
                    scanList.remove(at: index)
                } else {
                    assertionFailure("impossible")
                }
            } // switch
            
            #if DEBUG
            let set = Set(scanList)
            assert(set.count == scanList.count)
            #endif

        } // while
        
        if !pins.isEmpty {
            pins.sort(by: { $0.mA < $1.mA })
            for i in 0..<pins.count {
                pins[i] = Pin(i: i, pin: pins[i])
            }
        }

        return pins
    }
    
    private func devide(edge: ABEdge, id: Int, cross: FixVec, nextId: Int) -> DivideResult {
        let ltPart = ABEdge(parent: edge, e0: edge.e0, e1: cross)
        let rtPart = ABEdge(parent: edge, e0: cross, e1: edge.e1)

#if DEBUG
        // left
        let evRem = SwipeEvent(sort: ltPart.e1.bitPack, action: .remove, edgeId: nextId, point: ltPart.e1)
        // right
        let evAdd = SwipeEvent(sort: rtPart.e0.bitPack, action: .add, edgeId: id, point: rtPart.e0)
#else
        // left
        let evRem = SwipeEvent(sort: ltPart.e1.bitPack, action: .remove, edgeId: nextId)
        // right
        let evAdd = SwipeEvent(sort: rtPart.e0.bitPack, action: .add, edgeId: id)
#endif

        return DivideResult(
            ltPart: ltPart,
            rtPart: rtPart,
            remEvent: evRem,
            addEvent: evAdd
        )
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
                let e = ABEdge(shapeId: shapeId, a: p0, b: p1)
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
        if e0.shapeId == 0 {
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
