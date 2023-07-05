//
//  EventQueue.swift
//  
//
//  Created by Nail Sharipov on 03.07.2023.
//

struct EventQueue {
    
    private var events: [SwipeEvent]

    @inlinable
    var hasNext: Bool {
        !events.isEmpty
    }
    
    @inlinable
    init(edges: [ABEdge]) {
        events = [SwipeEvent]()
        let capacity = 2 * (edges.count + 4)
        events.reserveCapacity(capacity)
        
        for i in 0..<edges.count {
            let edge = edges[i]
            
#if DEBUG
            events.append(SwipeEvent(sort: edge.e1.bitPack, action: .remove, edgeId: i, point: edge.e1))
            events.append(SwipeEvent(sort: edge.e0.bitPack, action: .add, edgeId: i, point: edge.e0))
#else
            events.append(SwipeEvent(sort: edge.e1.bitPack, action: .remove, edgeId: i))
            events.append(SwipeEvent(sort: edge.e0.bitPack, action: .add, edgeId: i))
#endif
        }
     
        events.sort {$0 > $1}
    }

    @inlinable
    init(edges: [FixerEdge]) {
        events = [SwipeEvent]()
        let capacity = 2 * (edges.count + 4)
        events.reserveCapacity(capacity)
        
        
        for i in 0..<edges.count {
            let edge = edges[i]

    #if DEBUG
            events.append(SwipeEvent(sort: edge.b.bitPack, action: .remove, edgeId: i, point: edge.b))
            events.append(SwipeEvent(sort: edge.a.bitPack, action: .add, edgeId: i, point: edge.a))
    #else
            events.append(SwipeEvent(sort: edge.b.bitPack, action: .remove, edgeId: i))
            events.append(SwipeEvent(sort: edge.a.bitPack, action: .add, edgeId: i))
    #endif

        }

        events.sort {$0 > $1}
    }
    
    // get a next event
    @inlinable
    mutating func next() -> SwipeEvent {
        events.removeLast()
    }
    
    // add event
    @inlinable
    mutating func add(events newEvents: [SwipeEvent], at sort: Int64) {
        let index = events.findIndexAnyResult(value: sort)

        for event in newEvents where event.action == .add {
            let i = events.lowerBoundary(value: event.sort, index: index)
            events.insert(event, at: i)
        }
        
        for event in newEvents where event.action == .remove {
            let i = events.upperBoundary(value: event.sort, index: index)
            events.insert(event, at: i)
        }
    }
}

// Binary search for reversed array
extension Array where Element == SwipeEvent {

    @inlinable
    /// Find index of first element equal original or first element bigger then original if no exact elements is present
    /// - Parameters:
    ///   - value: original element
    ///   - start: from where to start (mostly it's index of a)
    /// - Returns: index of lower boundary
    func lowerBoundary(value a: Int64, index: Int) -> Int {
        let last = count - 1
        var i = index
        if i > last {
            i = last
        } else if i < 0 {
            i = 0
        }
        var x = self[i].sort

        while i > 0 && x <= a  {
            i -= 1
            x = self[i].sort
        }
        
        while i < last && x > a  {
            i += 1
            x = self[i].sort
        }
        
        if x > a {
            i += 1
        }
        
        return i
    }
    
    @inlinable
    /// Find index of first element bigger then original
    /// - Parameters:
    ///   - value: original element
    ///   - start: from where to start (mostly it's index of a)
    /// - Returns: index of upper boundary
    func upperBoundary(value a: Int64, index: Int) -> Int {
        let last = count - 1
        var i = index
        if i > last {
            i = last
        } else if i < 0 {
            i = 0
        }
        var x = self[i].sort

        while i > 0 && x < a  {
            i -= 1
            x = self[i].sort
        }

        while i < last && x >= a  {
            i += 1
            x = self[i].sort
        }
        
        if x >= a {
            i += 1
        }
        
        return i
    }

    @inlinable
    /// Find index of element. If element is not found return index where it must be
    /// - Parameters:
    ///   - value: target element
    /// - Returns: index of element
    func findIndexAnyResult(value a: Int64) -> Int {
        var left = 0
        var right = count - 1

        var j = -1
        var i = (left + right) / 2
        var x = self[i].sort
        
        while i != j {
            if x < a {
                right = i - 1
            } else if x > a {
                left = i + 1
            } else {
                return i
            }
            
            j = i
            i = (left + right) / 2

            x = self[i].sort
        }
        
        if x > a {
            i = i + 1
        }

        return i
    }
}
