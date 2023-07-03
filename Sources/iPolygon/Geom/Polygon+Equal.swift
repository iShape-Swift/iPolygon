//
//  Polygon+Equal.swift
//  
//
//  Created by Nail Sharipov on 03.07.2023.
//

import iFixFloat

// do not work with duplicates
public extension Array where Element == FixVec {
    
    func isEqual(_ other: [FixVec]) -> Bool {
        let n = count
        guard n == other.count else { return false }
        
        let a0 = self[0]

        var ib = 0
        
        while ib < n {
            if other[ib] == a0 {
                break
            }
            ib += 1
        }

        guard ib < n else {
            return false
        }
        
        var ia = 1
        while ia < n {
            ib = (ib + 1) % n

            if other[ib] != self[ia] {
                return false
            }
            
            ia += 1
        }

        return true
    }
}
