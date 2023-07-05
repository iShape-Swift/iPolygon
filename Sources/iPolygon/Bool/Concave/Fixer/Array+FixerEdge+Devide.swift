//
//  Array+FixerEdge+Devide.swift
//  
//
//  Created by Nail Sharipov on 21.06.2023.
//

import iFixFloat

private struct EdgeDivideResult {
    let leftPart: FixerEdge
    let rightPart: FixerEdge
    let removeEvent: SwipeEvent
    let addEvent: SwipeEvent
    let isBend: Bool
}

struct CrossResult {
    let isBendPath: Bool
    let edges: [FixerEdge]
}

extension Array where Element == FixerEdge {
    
    func cross() -> CrossResult {
        var edges = self
        
        var evQueue = EventQueue(edges: edges)
        
        var scanList = [Int]()
        scanList.reserveCapacity(16)
        
        var isAnyBend = false
        
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
                    let crossResult = thisEdge.cross(other: otherEdge)
                    
                    switch crossResult.type {
                    case .not_cross, .end_a0_b0, .end_a0_b1, .end_a1_b0, .end_a1_b1, .same_line:
                        j += 1
                    case .pure:
                        let cross = crossResult.point
                        
                        // devide edges
                        
                        // for this edge
                        // create new left part (new edge id), put 'remove' event
                        // update right part (keep old edge id), put 'add' event
                        
                        let thisNewId = edges.count
                        let thisResult = self.devide(edge: thisEdge, id: thisId, cross: cross, nextId: thisNewId)
                        
                        edges.append(thisResult.leftPart)
                        thisEdge = thisResult.leftPart
                        edges[thisId] = thisResult.rightPart    // update old edge (right part)
                        thisId = thisNewId                      // we are now left part with new id
                        
                        newScanId = thisNewId
                        
                        // for other(scan) edge
                        // create new left part (new edge id), put 'remove' event
                        // update right part (keep old edge id), put 'add' event
                        
                        let otherNewId = edges.count
                        let otherResult = self.devide(edge: otherEdge, id: otherId, cross: cross, nextId: otherNewId)
                        
                        edges.append(otherResult.leftPart)
                        edges[otherId] = otherResult.rightPart
                        
                        scanList[j] = otherNewId
                        
                        // insert events
                        
                        evQueue.add(events: [
                            thisResult.removeEvent,
                            otherResult.removeEvent,
                            thisResult.addEvent,
                            otherResult.addEvent
                        ], at: thisResult.removeEvent.sort)
                        
                        // is cross point bend path
                        
                        isAnyBend = isAnyBend || thisResult.isBend || otherResult.isBend
                        
                        j += 1
                    case .end_b0, .end_b1:
                        let cross = crossResult.point
                        
                        // devide this edge
                        
                        // create new left part (new edge id), put 'remove' event
                        // update right part (keep old edge id), put 'add' event
                        
                        let thisNewId = edges.count
                        let thisResult = self.devide(edge: thisEdge, id: thisId, cross: cross, nextId: thisNewId)
                        
                        thisEdge = thisResult.leftPart
                        edges.append(thisResult.leftPart)
                        edges[thisId] = thisResult.rightPart    // update old edge (right part)
                        thisId = thisNewId                      // we are now left part with new id
                        
                        newScanId = thisNewId
                        
                        // insert events
                        
                        evQueue.add(events: [
                            thisResult.removeEvent,
                            thisResult.addEvent
                        ], at: thisResult.removeEvent.sort)
                        
                        // is cross point bend path
                        
                        isAnyBend = isAnyBend || thisResult.isBend
                        
                        j += 1
                    case .end_a0, .end_a1:
                        let cross = crossResult.point
                        
                        // devide other(scan) edge
                        
                        // create new left part (new edge id), put 'remove' event
                        // update right part (keep old edge id), put 'add' event
                        
                        let otherNewId = edges.count
                        let otherResult = self.devide(edge: otherEdge, id: otherId, cross: cross, nextId: otherNewId)
                        
                        edges.append(otherResult.leftPart)
                        edges[otherId] = otherResult.rightPart
                        
                        scanList[j] = otherNewId
                        
                        // insert events
                        
                        evQueue.add(events: [
                            otherResult.removeEvent,
                            otherResult.addEvent
                        ], at: otherResult.removeEvent.sort)
                        
                        // is cross point bend path
                        
                        isAnyBend = isAnyBend || otherResult.isBend
                        
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
        
        return CrossResult(isBendPath: isAnyBend, edges: edges)
    }
    
    private func devide(edge: FixerEdge, id: Int, cross: FixVec, nextId: Int) -> EdgeDivideResult {
        let leftPart = FixerEdge(a: edge.a, b: cross)
        let rightPart = FixerEdge(a: cross, b: edge.b)

    #if DEBUG
        // left
        let evRemove = SwipeEvent(sort: leftPart.b.bitPack, action: .remove, edgeId: nextId, point: leftPart.b)
        // right
        let evAdd = SwipeEvent(sort: rightPart.a.bitPack, action: .add, edgeId: id, point: cross)
    #else
        let evRemove = SwipeEvent(sort: bitPack, action: .remove, edgeId: nextId)
        let evAdd = SwipeEvent(sort: bitPack, action: .add, edgeId: id)
    #endif
        
        let isBend = Triangle.isNotLine(p0: edge.a, p1: edge.b, p2: cross)

        return EdgeDivideResult(
            leftPart: leftPart,
            rightPart: rightPart,
            removeEvent: evRemove,
            addEvent: evAdd,
            isBend: isBend
        )
    }

}
