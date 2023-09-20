//
//  GeohashNumbered.swift
//
//
//  Created by Tomas Harkema on 12/09/2023.
//

import Foundation

public protocol GeohashLengthed {
    static var length: UInt32 { get }
}

public struct GeohashLength11: GeohashLengthed {
    public static let length: UInt32 = 11
}

public struct GeohashLength10: GeohashLengthed {
    public static let length: UInt32 = 10
}

public struct GeohashLength9: GeohashLengthed {
    public static let length: UInt32 = 9
}

public struct GeohashLength8: GeohashLengthed {
    public static let length: UInt32 = 8
}

public struct GeohashLength7: GeohashLengthed {
    public static let length: UInt32 = 7
}

public struct GeohashLength6: GeohashLengthed {
    public static let length: UInt32 = 6
}

public struct GeohashLength5: GeohashLengthed {
    public static let length: UInt32 = 5
}

public struct GeohashLength4: GeohashLengthed {
    public static let length: UInt32 = 4
}

public struct GeohashLength3: GeohashLengthed {
    public static let length: UInt32 = 3
}

public struct GeohashLength2: GeohashLengthed {
    public static let length: UInt32 = 2
}

public struct GeohashLength1: GeohashLengthed {
    public static let length: UInt32 = 1
}
