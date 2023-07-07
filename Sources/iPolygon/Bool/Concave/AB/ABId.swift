//
//  ABId.swift
//  
//
//  Created by Nail Sharipov on 07.07.2023.
//


typealias ABId = Int

@usableFromInline
enum ABShapeId: Int {
    case a = 0
    case b = 1
}

extension ABId {
    
    @inlinable
    init(index: Int, shapeId: ABShapeId) {
#if DEBUG
        self = (index * 10) | shapeId.rawValue
#else
        self = (index << 1) | shapeId.rawValue
#endif
        
    }
    
    @inlinable
    var shapeId: ABShapeId {
        let rawValue = self & 1
        return rawValue == ABShapeId.a.rawValue ? .a : .b
    }

}

struct ABIdGenerator {
    
    private (set) var counter: Int
    
    @inlinable
    init(counter: Int) {
        self.counter = counter
    }
    
    @inlinable
    mutating func next(shapeId: ABShapeId) -> ABId {
        let index = counter
        counter += 1
        return ABId(index: index, shapeId: shapeId)
    }
    
}
