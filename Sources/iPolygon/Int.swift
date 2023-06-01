//
//  Int.swift
//  
//
//  Created by Nail Sharipov on 16.05.2023.
//

extension Int {

    @inlinable
    func next(_ n: Int) -> Int {
        let x = self + 1
        return x == n ? 0 : x
    }
    
    @inlinable
    func prev(_ n: Int) -> Int {
        let x = self - 1
        return x < 0 ? (n - 1) : x
    }
}
