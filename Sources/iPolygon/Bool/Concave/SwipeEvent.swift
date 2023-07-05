//
//  SwipeEvent.swift
//  
//
//  Created by Nail Sharipov on 23.06.2023.
//

import iFixFloat

@usableFromInline
struct SwipeEvent: Comparable, Equatable {

#if DEBUG
    static let empty = SwipeEvent(sort: 0, action: .add, edgeId: -1, point: .zero)
#else
    static let empty = SwipeEvent(sort: 0, action: .add, edgeId: -1)
#endif
    
    @usableFromInline
    enum Action: Int {
        case add = 1
        case remove = 0
    }

    @usableFromInline
    let sort: Int64
    
    @usableFromInline
    let action: Action
    
    @usableFromInline
    let edgeId: Int
    
#if DEBUG
    
    @usableFromInline
    let point: FixVec

    @inlinable
    init(sort: Int64, action: Action, edgeId: Int, point: FixVec) {
        self.sort = sort
        self.action = action
        self.edgeId = edgeId
        self.point = point
    }
#else
    
    @inlinable
    init(sort: Int64, action: Action, edgeId: Int) {
        self.sort = sort
        self.action = action
        self.edgeId = edgeId
    }
#endif
    
    @usableFromInline
    static func < (lhs: SwipeEvent, rhs: SwipeEvent) -> Bool {
        if lhs.sort == rhs.sort {
            return lhs.action.rawValue < rhs.action.rawValue
        } else {
            return lhs.sort < rhs.sort
        }
    }
}
