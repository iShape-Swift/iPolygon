//
//  MPoly.swift
//  
//
//  Created by Nail Sharipov on 02.06.2023.
//

import iFixFloat

struct MPoly {
        
    var next: Vx
    var prev: Vx

    @inlinable
    init(start: Vx) {
        next = start
        prev = start
    }
    
    @inlinable
    init(next: Vx, prev: Vx) {
        self.next = next
        self.prev = prev
    }

}
