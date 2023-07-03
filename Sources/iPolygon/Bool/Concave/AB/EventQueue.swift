//
//  EventQueue.swift
//  
//
//  Created by Nail Sharipov on 03.07.2023.
//

struct EventQueue {
    
    private struct Node {

        static let empty = Node(prev: -1, next: -1, event: .empty)
        
        var prev: Int
        var next: Int
        let event: SwipeEvent
    }

    private var first: Int
    private var nodes: [Node]
    private var freeIndices: [Int]

    var isEmpty: Bool {
        first == -1
    }

    init(events: [SwipeEvent]) {
        let n = events.count

        nodes = [Node](repeating: .empty, count: n)
        freeIndices = [Int]()
        
        guard n > 0 else {
            first = -1
            return
        }
        
        var j = -1
        var i = 0
        while i < n - 1 {
            nodes[i] = Node(prev: j, next: i + 1, event: events[i])
            j = i
            i += 1
        }
        
        nodes[i] = Node(prev: i - 1, next: -1, event: events[i])

        first = 0
    }

    // get a first event
    mutating func pop() -> SwipeEvent {
        let node = nodes[first]
        freeIndices.append(first)
        
        first = node.next
        if first != -1 {
            var next = nodes[first]
            next.prev = -1
            nodes[first] = next
        }
        
        return node.event
    }
    
    // add event
    mutating func add(event: SwipeEvent) {
        guard first != -1 else {
            first = nextFreeIndex()
            nodes[first] = Node(prev: -1, next: -1, event: event)
            
            return
        }
        
        var next = nodes[first]
        var nextIndex = first
        
        while next.event < event && next.next != -1 {
            nextIndex = next.next
            next = nodes[nextIndex]
        }

        let index = self.nextFreeIndex()

        if next.event < event {
            // add after
            
            next.next = index // was -1
            nodes[index] = Node(prev: nextIndex, next: -1, event: event)
        } else {
            // add before

            if next.prev != -1 {
                var prev = nodes[next.prev]
                prev.next = index
                nodes[next.prev] = prev
            } else {
                first = index
            }
            nodes[index] = Node(prev: next.prev, next: nextIndex, event: event)

            next.prev = index
        }

        nodes[nextIndex] = next
    }
    
    mutating private func nextFreeIndex() -> Int {
        guard freeIndices.isEmpty else {
            return freeIndices.removeLast()
        }
        
        let index = nodes.count
        
        nodes.append(.empty)
        
        return index
    }
}
