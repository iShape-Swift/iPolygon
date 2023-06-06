//
//  Polygon+Area.swift
//  
//
//  Created by Nail Sharipov on 18.05.2023.
//

import iFixFloat

public extension Array where Element == FixVec {
    
    var area: FixFloat {
        let n = self.count
        var p0 = self[n - 1]

        var area: FixFloat = 0
        
        for p1 in self {
            area += p1.unsafeCrossProduct(p0)
            p0 = p1
        }
        
        return area >> (FixFloat.fractionBits + 1)
    }
}
