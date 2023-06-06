//
//  FixShape+mLayout.swift
//  
//
//  Created by Nail Sharipov on 02.06.2023.
//

import iFixFloat

struct MLayout {
    let startList: [Int]
    let vertices: [MVert]
    let sliceList: [MSlice]
}

extension FixShape {

    var mLayout: MLayout {
        let nLayout = self.nLayout
        
        var verts = nLayout.verts
        let nodes = nLayout.nodes
        
        var startList = [Int]()
        var sliceList = [MSlice]()
        var mPolies = [MPoly]()
        
        var j = 0
        while j < nodes.count {
            let node = nodes[j]

            let px = Self.fill(mPolies: &mPolies, verts: verts, stop: node.sort)
            
            let v = verts[node.index]
            
            switch node.type {
            case .end:
                assert(px.next == px.prev)
                let pIndex = px.next
                mPolies.remove(at: pIndex)
            case .start:
                startList.append(node.index)
                mPolies.append(MPoly(start: v.vert))
            case .split:
                var pIndex: Int = .empty
                for i in 0..<mPolies.count {
                    if Self.isContain(mPoly: mPolies[i], point: v.vert.point, verts: verts) {
                        pIndex = i
                        break
                    }
                }
                
                assert(pIndex != .empty)
                
                let mPoly = mPolies[pIndex]

                let a = mPoly.next.point
                let b = mPoly.prev.point
                
                let sp = v.vert.point
                
                let compare = a.x == b.x ? sp.sqrDistance(a) < sp.sqrDistance(b) : a.x < b.x
                
                if compare {
                    let nv = mPoly.next
                    let sv = v.vert
                    // next
                    let s = verts.newNext(a: sv.index, b: nv.index)
                    sliceList.append(s)
                    
                    mPolies[pIndex] = MPoly(start: s.b)
                    startList.append(s.b.index)

                    mPolies.append(MPoly(next: nv, prev: mPoly.prev))
                } else {
                    let s = verts.newNext(a: mPoly.prev.index, b: v.vert.index)
                    sliceList.append(s)
                    
                    mPolies[pIndex] = MPoly(next: s.a, prev: s.b)
                    startList.append(s.a.index)

                    mPolies.append(MPoly(next: mPoly.next, prev: v.vert))
                }

            case .merge:
                let nextPoly = mPolies[px.next]
                let prevPoly = mPolies[px.prev]
                
                let prev = verts[prevPoly.prev.index]
                let next = verts[nextPoly.next.index]
                let nextIndex = j + 1
                let split: Int
                if nodes.count > nextIndex {
                    let nextNode = nodes[nextIndex]
                    split = nextNode.type == .split || nextNode.type == .end ? nextNode.index : .empty
                } else {
                    split = .empty
                }

                let ms = Self.eliminateMerge(prev: prev, next: next, merge: v.vert.index, split: split, verts: verts)

                switch ms.type {
                case .direct:
                    j = nextIndex
                    
                    let s = verts.newNext(a: ms.b, b: ms.a)
                    sliceList.append(s)

                    mPolies[px.next] = MPoly(
                        next: nextPoly.next,
                        prev: s.a
                    )
                case .next:
                    let s = verts.newNext(a: ms.b, b: ms.a)
                    sliceList.append(s)
                    mPolies.remove(at: px.next)
                case .prev:
                    let s = verts.newNext(a: ms.a, b: ms.b)
                    sliceList.append(s)
                    mPolies.remove(at: px.prev)
                }
            }
            
            j += 1
        } // while
            
        return MLayout(startList: startList, vertices: verts, sliceList: sliceList)
    }

    private struct NavIndex {
        let next: Int // next
        let prev: Int // prev
    }

    private static func fill(mPolies: inout [MPoly], verts: [MVert], stop: FixFloat) -> NavIndex {
        var nextPolyIx: Int = .empty
        var prevPolyIx: Int = .empty
        
        for i in 0..<mPolies.count {
            var mPoly = mPolies[i]
            
            var n0 = verts[mPoly.next.index]
            var n1 = verts[n0.next]
            while n1.vert.point.bitPack < stop {
                n0 = n1
                n1 = verts[n1.next]
            }
            
            if n1.vert.point.bitPack == stop {
                mPoly.next = n1.vert
                prevPolyIx = i
            } else {
                mPoly.next = n0.vert
            }
            
            var p0 = verts[mPoly.prev.index]
            var p1 = verts[p0.prev]
            while p1.vert.point.bitPack < stop {
                p0 = p1
                p1 = verts[p1.prev]
            }
            
            if p1.vert.point.bitPack == stop {
                mPoly.prev = p1.vert
                nextPolyIx = i
            } else {
                mPoly.prev = p0.vert
            }
            
            mPolies[i] = mPoly
        }
        
        return NavIndex(next: nextPolyIx, prev: prevPolyIx)
    }
    
    private enum MType {
        case direct
        case next
        case prev
    }
    
    private struct MSolution {
        let type: MType
        let a: Int
        let b: Int
    }

    private static func eliminateMerge(prev: MVert, next: MVert, merge: Int, split: Int, verts: [MVert]) -> MSolution {
        let a0 = next.vert.point
        let a1 = verts[next.next].vert.point
        let b1 = verts[prev.prev].vert.point
        let b0 = prev.vert.point
        
        // shall we use split node to resolve?
        if split != .empty {
            let sv = verts[split].vert.point
            let minX = min(a1.x, b1.x)
            if sv.x < minX && Self.isContain(point: sv, a0: a0, a1: a1, b0: b0, b1: b1) {
                return MSolution(type: .direct, a: merge, b: split)
            }
        }
        
        let m = verts[merge].vert.point
        
        let compare = a1.x == b1.x ? m.sqrDistance(a1) < m.sqrDistance(b1) : a1.x < b1.x
        
        if compare {
            return MSolution(type: .next, a: merge, b: next.next)
        } else {
            return MSolution(type: .prev, a: merge, b: prev.prev)
        }
    }
    
    private static func isContain(mPoly: MPoly, point: FixVec, verts: [MVert]) -> Bool {
        let a0 = verts[mPoly.next.index]
        let a1 = verts[a0.next]
        
        let b0 = verts[mPoly.prev.index]
        let b1 = verts[b0.prev]

        return isContain(point: point, a0: a0.vert.point, a1: a1.vert.point, b0: b0.vert.point, b1: b1.vert.point)
    }
    
    private static func isContain(point: FixVec, a0: FixVec, a1: FixVec, b0: FixVec, b1: FixVec) -> Bool {
        let sa = (a1 - a0).unsafeCrossProduct(point - a0)
        let sb = (b1 - b0).unsafeCrossProduct(point - b0)
        
        return sa <= 0 && sb >= 0
    }
}
