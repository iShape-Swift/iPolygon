//
//  Vx.swift
//  
//
//  Created by Nail Sharipov on 04.06.2023.
//

import iFixFloat

@usableFromInline
struct Vx {
    
    static let empty = Vx(id: .empty, index: .empty, point: .zero)

    @usableFromInline
    let id: Int // index in original array
    
    @usableFromInline
    let index: Int
    
    @usableFromInline
    let point: FixVec

    @inlinable
    init(id: Int, index: Int, point: FixVec) {
        self.id = id
        self.index = index
        self.point = point
    }

    @inlinable
    init(index: Int, vx: Vx) {
        self.index = index
        self.id = vx.id
        self.point = vx.point
    }
    
}
