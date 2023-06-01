//
//  Convex+Centroid.swift
//  
//
//  Created by Nail Sharipov on 23.05.2023.
//

import iFixFloat

public struct Centroid {
    public static let zero = Centroid(area: 0, center: .zero)
    public let area: FixFloat
    public let center: FixVec
}

public extension Array where Element == FixVec {
    
    var centroid: Centroid {
        let n = count
        guard n > 2 else {
            if n == 2 {
                return Centroid(area: 0, center: (self[0] + self[1]).half)
            } else if n == 1 {
                return Centroid(area: 0, center: self[0])
            } else {
                return Centroid(area: 0, center: .zero)
            }
        }
        
        var center = FixVec.zero
        var area: Int64 = 0
        
        var p0 = self[n - 1]

        for p1 in self {
            let crossProduct = p1.unsafeCrossProduct(p0)
            area += crossProduct

            center = center + (p0 + p1).unsafeMul(crossProduct)

            p0 = p1
        }

        let s = 3 * area
        let x: FixFloat
        let y: FixFloat
        if s != 0 {
            x = center.x / s
            y = center.y / s
            area = area >> (1 + FixFloat.fractionBits)
        } else {
            var p0 = self[n - 1]
            var minX = p0.x
            var maxX = p0.x
            var minY = p0.y
            var maxY = p0.y
            for p1 in self {
                p0 = p1
                minX = Swift.min(minX, p0.x)
                maxX = Swift.max(maxX, p0.x)
                minY = Swift.min(minY, p0.y)
                maxY = Swift.max(maxY, p0.y)
            }
            x = (minX + maxX) / 2
            y = (minY + maxY) / 2
        }

        return Centroid(area: area, center: FixVec(x, y))
    }
    
}
