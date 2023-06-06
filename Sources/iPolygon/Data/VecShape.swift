//
//  VecShape.swift
//  
//
//  Created by Nail Sharipov on 01.06.2023.
//

import iFixFloat
import CoreGraphics

public struct VecShape {
    
    public let paths: [[Vec]]
    
    public init(paths: [[Vec]]) {
        self.paths = paths
    }
    
    public var shape: FixShape {
        var result = [[FixVec]]()
        for path in paths {
            result.append(path.map { $0.fix })
        }
        
        return FixShape(paths: result)
    }
    
}
