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
