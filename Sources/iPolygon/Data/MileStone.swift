//
//  MileStone.swift
//  
//
//  Created by Nail Sharipov on 16.05.2023.
//

import iFixFloat

public struct MileStone: Equatable, Hashable {
    
    static let zero = MileStone(index: 0)
    static let empty = MileStone(index: -1)

    public let index: Int
    public let offset: FixFloat

    @inlinable
    init(index: Int, offset: FixFloat = 0) {
        self.index = index
        self.offset = offset
    }
    
    @inlinable
    public static func < (lhs: MileStone, rhs: MileStone) -> Bool {
        if lhs.index != rhs.index {
            return lhs.index < rhs.index
        }

        return lhs.offset < rhs.offset
    }
    
    @inlinable
    public static func > (lhs: MileStone, rhs: MileStone) -> Bool {
        if lhs.index != rhs.index {
            return lhs.index > rhs.index
        }

        return lhs.offset > rhs.offset
    }
    
    @inlinable
    public static func >= (lhs: MileStone, rhs: MileStone) -> Bool {
        if lhs.index != rhs.index {
            return lhs.index > rhs.index
        }

        return lhs.offset >= rhs.offset
    }
    
    @inlinable
    public static func == (lhs: MileStone, rhs: MileStone) -> Bool {
        return lhs.index == rhs.index && lhs.offset == rhs.offset
    }
    
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        hasher.combine(offset)
    }

    @inlinable
    static public func directLength(_ n: Int, m0: MileStone, m1: MileStone) -> Int {
        guard m0 != m1 else {
            return 0
        }

        var count = 0
        if m0.index == m1.index {
            count = m0.offset < m1.offset ? 0 : n
        } else if m0.index < m1.index {
            count = m1.index - m0.index
        } else {
            count = m0.index + n - m1.index
        }
        
        if m0.offset != 0 {
            count += 1
        }
        if m1.offset != 0 {
            count += 1
        }
        
        return count
    }
    
    public static func sameEdgeIndex(_ n: Int, m0: MileStone, m1: MileStone) -> Int {
        guard m0.index != m1.index else {
            return m0.index
        }
        
        if m0.offset == 0 && m1.index.next(n) == m0.index {
            return m1.index
        } else if m1.offset == 0 && m0.index.next(n) == m1.index {
            return m0.index
        }
        
        return -1
    }
}

#if DEBUG
extension MileStone: CustomStringConvertible {
    
    public var description: String {
        "(\(index), \(offset))"
    }
    
}
#endif
