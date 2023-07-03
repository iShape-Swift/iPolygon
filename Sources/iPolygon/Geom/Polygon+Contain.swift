//
//  File.swift
//  
//
//  Created by Nail Sharipov on 29.06.2023.
//

import iFixFloat

public extension Array where Element == FixVec {
    
    func isContain(point p: FixVec) -> Bool {
        let n = self.count
        var isContain = false
        var b = self[n - 1]
        for i in 0..<n {
            let a = self[i]
            
            let isInRange = (a.y > p.y) != (b.y > p.y)
            if isInRange {
                let dx = b.x - a.x
                let dy = b.y - a.y
                let sx = (p.y - a.y) * dx / dy + a.x
                if p.x < sx {
                    isContain = !isContain
                }
            }
            b = a
        }
        
        return isContain
    }
}
