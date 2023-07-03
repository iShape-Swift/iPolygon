//
//  Array+Fixer.swift
//  
//
//  Created by Nail Sharipov on 11.06.2023.
//

import iFixFloat

public extension Array where Element == FixVec {
    
    func fix() -> [[FixVec]] {
        let clean = self.removedDegenerates()
        guard clean.count > 2 else {
            return [clean]
        }
        var edges = clean.createEdges()
        
        var count = 0
        
        var isModified = true
        repeat {
            let result = edges.divide()
            edges = result.edges
            isModified = result.isBendPath
            count += 1
        } while isModified
        
        debugPrint("divide count: \(count)")
        
        guard edges.count != clean.count else { return [clean] }
        
        let graph = FixerGraph(edges: edges)
        
        return edges.union(graph: graph)
    }
    
    private func createEdges() -> [FixerEdge] {
        var edges = [FixerEdge](repeating: .zero, count: count)
        var a = self[count - 1]
        for i in 0..<count {
            let b = self[i]
            if a.bitPack > b.bitPack {
                edges[i] = FixerEdge(a: b, b: a)
            } else {
                edges[i] = FixerEdge(a: a, b: b)
            }
            a = b
        }
        return edges
    }
}
