//
//  FixShape+nLayout.swift
//  
//
//  Created by Nail Sharipov on 01.06.2023.
//

import iFixFloat

@usableFromInline
enum MNodeType: Int {
    case end
    case start
    case split
    case merge
}

@usableFromInline
struct MNode {
    
    @usableFromInline
    static let empty = MNode(index: .empty, type: .start, sort: .zero)
    
    @usableFromInline
    let type: MNodeType
    
    @usableFromInline
    let index: Int

    @usableFromInline
    let sort: FixFloat
    
    @inlinable
    init(index: Int, type: MNodeType, sort: FixFloat) {
        self.index = index
        self.type = type
        self.sort = sort
    }
}

@usableFromInline
struct NodeLayout {
    
    @usableFromInline
    let verts: [MVert]
    
    @usableFromInline
    let nodes: [MNode]
    
    @inlinable
    init(verts: [MVert], nodes: [MNode]) {
        self.verts = verts
        self.nodes = nodes
    }
}

extension FixShape {
    
    @inlinable
    var nLayout: NodeLayout {
        var n = 0
        for path in paths {
            n += path.count
        }
        
        var verts = [MVert](repeating: .empty, count: n)
        var nodes = [MNode]()
        
        var s = 0
        for j in 0..<paths.count {
            
            let path = paths[j]
            
            var i0 = path.count - 2

            var p0 = path[i0]

            var i1 = i0 + 1
            
            var p1 = path[i1]
            
            for i2 in 0..<path.count {

                let i = i1 + s
                
                let p2 = path[i2]

                let b0 = p0.bitPack
                let b1 = p1.bitPack
                let b2 = p2.bitPack

                let c0 = b0 > b1 && b1 < b2
                let c1 = b0 < b1 && b1 > b2
                
                if c0 || c1 {
                    let isCW = Triangle.isClockwise(p0: p0, p1: p1, p2: p2)
                    let type: MNodeType = c0 ? (isCW ? .start : .split) : (isCW ? .end : .merge)
                    nodes.append(MNode(index: i, type: type, sort: b1))
                }

                verts[i] = MVert(next: i2 + s, prev: i0 + s, vert: Vx(id: i, index: i, point: p1))
                
                i0 = i1
                i1 = i2
                
                p0 = p1
                p1 = p2
            }
            
            s += path.count
        }
        
        nodes.sort(by: {
            if $0.sort != $1.sort {
                return $0.sort < $1.sort
            } else {
                return $0.type.rawValue < $1.type.rawValue
            }
        })
        
        return NodeLayout(verts: verts, nodes: nodes)
    }
}
