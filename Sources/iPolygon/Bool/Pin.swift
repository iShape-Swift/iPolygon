//
//  Pin.swift
//  
//
//  Created by Nail Sharipov on 20.05.2023.
//

import iFixFloat

struct PointStone {
    let m: MileStone
    let p: FixVec
}

public enum PinType {
    case empty
    
    case into
    case into_empty
    case empty_into
    case into_out
    
    case out
    case empty_out
    case out_empty
    case out_into
}

public struct Pin {
   
    static let zero = Pin(p: .zero, mA: .zero, mB: .zero)
    
    public let i: Int
    public let p: FixVec
    public let mA: MileStone
    public let mB: MileStone
    public internal (set) var type: PinType = .empty
    
#if DEBUG
    public var a0: FixFloat = 0
    public var a1: FixFloat = 0
#endif
    
    init(i: Int = 0, p: FixVec, mA: MileStone, mB: MileStone, type: PinType = .empty) {
        self.i = i
        self.p = p
        self.mA = mA
        self.mB = mB
        self.type = type
    }
    
    init(i: Int, pin: Pin) {
        self.i = i
        self.p = pin.p
        self.mA = pin.mA
        self.mB = pin.mB
        self.type = pin.type
    }
    
    var a: PointStone {
        .init(m: mA, p: p)
    }

    var b: PointStone {
        .init(m: mB, p: p)
    }
}

public extension Array where Element == Pin {
    
    func next(pin: Pin) -> Pin {
        self[pin.i.next(count)]
    }
}
