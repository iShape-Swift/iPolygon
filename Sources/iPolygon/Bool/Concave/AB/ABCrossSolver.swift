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


public struct ABCrossSolver {
    
    public static func cross(pathA: [FixVec], pathB: [FixVec], bndA: Boundary, bndB: Boundary) -> ABCross {
        // at this time pathA and pathB must be correct!

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

        var edges = [ABEdge]()
        edges.append(contentsOf: aEdges)
        edges.append(contentsOf: bEdges)

        var events = edges.events
        
        var scanList = [Int]()
        scanList.reserveCapacity(16)

        var pins = [Pin]()
        
        while !events.isEmpty {
            let event = events.removeLast()

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
                    
                    let crossResult = thisEdge.cross(otherEdge)
                    
                    switch crossResult.type {
                    case .not_cross, .end_a0_b0, .end_a0_b1, .end_a1_b0, .end_a1_b1, .same_line:
                        // add pin
                        j += 1
                    case .pure:
                        let cross = crossResult.pin.p
                        
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

                        let index = events.findIndexAnyResult(value: thisResult.remEvent.sort)
                        
                        let remEvIndex0 = events.lowerBoundary(value: thisResult.remEvent.sort, index: index)
                        events.insert(thisResult.remEvent, at: remEvIndex0)

                        let remEvIndex1 = events.lowerBoundary(value: otherResult.remEvent.sort, index: index)
                        events.insert(otherResult.remEvent, at: remEvIndex1)

                        let addEvIndex0 = events.upperBoundary(value: thisResult.addEvent.sort, index: index)
                        events.insert(thisResult.addEvent, at: addEvIndex0)

                        let addEvIndex1 = events.upperBoundary(value: otherResult.addEvent.sort, index: index)
                        events.insert(otherResult.addEvent, at: addEvIndex1)

                        j += 1
                    case .end_b0, .end_b1:
                        let cross = crossResult.pin.p
                        
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
                        
                        let index = events.findIndexAnyResult(value: thisResult.remEvent.sort)
                        
                        let remEvIndex = events.lowerBoundary(value: thisResult.remEvent.sort, index: index)
                        events.insert(thisResult.remEvent, at: remEvIndex)
                        
                        let addEvIndex = events.upperBoundary(value: thisResult.addEvent.sort, index: index)
                        events.insert(thisResult.addEvent, at: addEvIndex)

                        j += 1
                    case .end_a0, .end_a1:
                        let cross = crossResult.pin.p
                        
                        // devide other(scan) edge

                        // create new left part (new edge id), put 'remove' event
                        // update right part (keep old edge id), put 'add' event

                        let otherNewId = edges.count
                        let otherResult = self.devide(edge: otherEdge, id: otherId, cross: cross, nextId: otherNewId)
                        
                        edges.append(otherResult.ltPart)
                        edges[otherId] = otherResult.rtPart
                        
                        scanList[j] = otherNewId
                        
                        // insert events

                        let index = events.findIndexAnyResult(value: otherResult.remEvent.sort)
                        
                        let remEvIndex = events.lowerBoundary(value: otherResult.remEvent.sort, index: index)
                        events.insert(otherResult.remEvent, at: remEvIndex)
                        
                        let addEvIndex = events.upperBoundary(value: otherResult.addEvent.sort, index: index)
                        events.insert(otherResult.addEvent, at: addEvIndex)
                        
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
            
            var clean = [Pin]()

            var p0 = pins[0]
            clean.append(p0)
            for i in 1..<pins.count {
                let pi = pins[i]
                if p0.mA != pi.mA {
                    clean.append(Pin(i: clean.count, pin: pi))
                    clean.append(pi)
                }
                p0 = pi
            }
            
            pins = clean
        }
        
        if pins.count == pathA.count && pathA.count == pathB.count {
            // looks like a == b
            if pathA.isEqual(pathB) {
                return ABCross(layout: .aEqB, navigator: .empty)
            }
        }

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
    
    private struct DivideResult {
        let ltPart: ABEdge
        let rtPart: ABEdge
        let remEvent: SwipeEvent
        let addEvent: SwipeEvent
    }
    
    static private func devide(edge: ABEdge, id: Int, cross: FixVec, nextId: Int) -> DivideResult {
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


private extension Array where Element == ABEdge {

    var events: [SwipeEvent] {
        var result = [SwipeEvent]()
        let capacity = 2 * (count + 4)
        result.reserveCapacity(capacity)
        
        for i in 0..<count {
            let edge = self[i]
            
#if DEBUG
            result.append(SwipeEvent(sort: edge.e1.bitPack, action: .remove, edgeId: i, point: edge.e1))
            result.append(SwipeEvent(sort: edge.e0.bitPack, action: .add, edgeId: i, point: edge.e0))
#else
            result.append(SwipeEvent(sort: edge.e1.bitPack, action: .remove, edgeId: i))
            result.append(SwipeEvent(sort: edge.e0.bitPack, action: .add, edgeId: i))
#endif
        }
     
        result.sort {$0 > $1}
        
        return result
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
