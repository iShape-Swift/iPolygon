//
//  EdgeBank.swift
//  
//
//  Created by Nail Sharipov on 06.07.2023.
//

import iFixFloat

// keep descending sorted edges by e0
struct EdgeBank {
    
    private (set) var counter: Int
    private (set) var edges: [ABEdge]
 
    var hasNext: Bool { !edges.isEmpty }

    init(edges: [ABEdge]) {
        self.edges = edges
        counter = edges.count
        self.edges.sort(by: { $0.e0.bitPack > $1.e0.bitPack })
    }
    
    mutating func nextId(shapeId: ABShapeId) -> Int {
        let id = ABId(index: counter, shapeId: shapeId)
        counter += 1
        return id
    }
    
    mutating func nextId() -> Int {
        let id = counter
        counter += 1
        return id
    }
    
}
