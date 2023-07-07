//
//  ABScanBank.swift
//  
//
//  Created by Nail Sharipov on 07.07.2023.
//

// keep two sorted list of edges by e1
struct ABScanBank {
    
    private var listA: [ABEdge]
    private var listB: [ABEdge]
    
    init() {
        listA = [ABEdge]()
        listA.reserveCapacity(8)
        listB = [ABEdge]()
        listB.reserveCapacity(8)
    }
    
    mutating func scanList(shapeId: ABShapeId, filter: Int64) -> [ABEdge] {
        if shapeId == .b { // invert!
            listA.removeAllE1(before: filter)
            return listA
        } else {
            listB.removeAllE1(before: filter)
            return listB
        }
    }
    
    mutating func add(edge: ABEdge) {
        if edge.id.shapeId == .a {
            listA.addE1(edge: edge)
        } else {
            listB.addE1(edge: edge)
        }
    }
    
}
