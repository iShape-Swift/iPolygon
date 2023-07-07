//
//  ConvexCrossSolver.swift
//  
//
//  Created by Nail Sharipov on 20.05.2023.
//

import iFixFloat

import iFixFloat

public struct ConvexCrossSolver {
    
    public static func intersect(pathA: [FixVec], pathB: [FixVec]) -> [Pin] {
        let bndA = Boundary(points: pathA)
        let bndB = Boundary(points: pathB)
        
        return Self.intersect(pathA: pathA, pathB: pathB, bndA: bndA, bndB: bndB)
    }

    public static func intersect(pathA: [FixVec], pathB: [FixVec], bndA: Boundary, bndB: Boundary) -> [Pin] {
        Self.bruteIntersect(pathA: pathA, pathB: pathB, bndA: bndA, bndB: bndB)
    }
    
}
