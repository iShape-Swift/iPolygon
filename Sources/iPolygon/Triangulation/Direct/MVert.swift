//
//  MVert.swift
//  
//
//  Created by Nail Sharipov on 01.06.2023.
//

import iFixFloat

@usableFromInline
struct MSlice {
    
    @usableFromInline
    let a: Vx
    
    @usableFromInline
    let b: Vx
    
    @inlinable
    init(a: Vx, b: Vx) {
        self.a = a
        self.b = b
    }
}

@usableFromInline
struct MVert {
    
    @usableFromInline
    static let empty = MVert(next: .empty, prev: .empty, vert: .empty)
    
    @usableFromInline
    fileprivate (set) var next: Int
    
    @usableFromInline
    fileprivate (set) var prev: Int
    
    @usableFromInline
    let vert: Vx
 
    @inlinable
    init(next: Int, prev: Int, vert: Vx) {
        self.next = next
        self.prev = prev
        self.vert = vert
    }
    
}

extension Array where Element == MVert {
    
    @inlinable
    mutating func newNext(a: Int, b: Int) -> MSlice {
        var aVert = self[a]
        var bVert = self[b]

        let count = self.count

        // add new verts
        
        let newA = MVert(
            next: count + 1,
            prev: aVert.prev,
            vert: Vx(index: count, vx: aVert.vert)
        )
        self.append(newA)
        
        self[aVert.prev].next = count

        let newB = MVert(
            next: bVert.next,
            prev: count,
            vert: Vx(index: count + 1, vx: bVert.vert)
        )

        self.append(newB)
        self[bVert.next].prev = count + 1
        
        // update old verts
        
        aVert.prev = b
        bVert.next = a
        
        self[a] = aVert
        self[b] = bVert
        
        return MSlice(a: newA.vert, b: newB.vert)
    }
    
    @inlinable
    func isIntersectNextReverse(p0: FixVec, p1: FixVec, start: Int) -> Bool {
        var n = self[start]
        let stop = p0.x
        let v = p1 - p0
        while n.vert.point.x <= stop {
            let s = v.crossProduct(n.vert.point - p0)
            if s >= 0 {
                return true
            }
            n = self[n.prev]
        }
        
        return false
    }

    @inlinable
    func isIntersectPrevReverse(p0: FixVec, p1: FixVec, start: Int) -> Bool {
        var n = self[start]
        let stop = p0.x
        let v = p1 - p0
        while n.vert.point.x > stop {
            let s = v.crossProduct(n.vert.point - p0)
            if s >= 0 {
                return true
            }
            n = self[n.next]
        }
        
        return false
    }
    
    @inlinable
    func isIntersect(p0: FixVec, p1: FixVec, next: Int, prev: Int) -> Bool {
        let isNext = isIntersectNextReverse(p0: p0, p1: p1, start: next)
        let isPrev = isIntersectPrevReverse(p0: p0, p1: p1, start: prev)
        
        return isNext || isPrev
    }

}
