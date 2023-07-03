//
//  SubArea.swift
//  
//
//  Created by Nail Sharipov on 30.06.2023.
//

import iFixFloat

extension Array where Element == FixVec {
    
    func directArea(s0: PointStone, s1: PointStone) -> FixFloat {
        guard s0.m != s1.m else {
            return 0
        }

        var area: FixFloat = 0
        var p0 = s0.p

        if s0.m < s1.m {
            // example from 3 to 6

            var i = s0.m.index + 1
            
            let last = s1.m.offset == 0 ? s1.m.index : s1.m.index + 1
            
            while i < last {
                let p1 = self[i]
                area -= p0.unsafeCrossProduct(p1)
                p0 = p1
                i += 1
            }
        } else {
            // example from 5 to 2
            var i = s0.m.index + 1
            
            while i < count {
                let p1 = self[i]
                area -= p0.unsafeCrossProduct(p1)
                p0 = p1
                i += 1
            }

            i = 0
            let last = s1.m.offset == 0 ? s1.m.index : s1.m.index + 1
            
            while i < last {
                let p1 = self[i]
                area -= p0.unsafeCrossProduct(p1)
                p0 = p1
                i += 1
            }
        }
        
        area -= p0.unsafeCrossProduct(s1.p)
        
        return area >> (FixFloat.fractionBits + 1)
    }
    
}
