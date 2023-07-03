//
//  ConvexOverlaySolver+Find.swift
//  
//
//  Created by Nail Sharipov on 17.05.2023.
//

import iFixFloat

public struct ConvexOverlaySolver {
    
    public static func find(polyA a: [FixVec], polyB b: [FixVec], bndA: Boundary, bndB: Boundary) -> [Pin] {
        var pins = ConvexCrossSolver.intersect(polyA: a, polyB: b, bndA: bndA, bndB: bndB)

        guard pins.count > 1 else {
            return pins
        }
        
        var areas = [FixFloat](repeating: 0, count: pins.count)
        
        for i in 0..<pins.count {
            let pin0 = pins[i]
            let pin1 = pins.next(pin: pin0)

            let aArea = a.directArea(s0: pin0.a, s1: pin1.a)
            let bArea = b.directArea(s0: pin0.b, s1: pin1.b)
            
            let area = aArea - bArea
            areas[i] = area
        }
        
        var a0 = areas[areas.count - 1]
        for i in 0..<areas.count {
            let a1 = areas[i]

            if a1 > 0 && a0 > 0 {
                pins[i].type = .into_out
            } else if a1 < 0 && a0 < 0 {
                pins[i].type = .out_into
            } else if a0 != 0 && a1 != 0 {
                if a1 > 0 {
                    pins[i].type = .out
                } else {
                    pins[i].type = .into
                }
            } else if a1 == 0 {
                if a0 > 0 {
                    pins[i].type = .into_empty
                } else {
                    pins[i].type = .out_empty
                }
            } else if a0 == 0 {
                if a1 > 0 {
                    pins[i].type = .empty_out
                } else {
                    pins[i].type = .empty_into
                }
            }

#if DEBUG
            pins[i].a0 = a0 / 1024
            pins[i].a1 = a1 / 1024
#endif
            
            a0 = a1
        }

        return pins
    }
    
}
