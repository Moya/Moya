//
//  String+md5.swift
//  Moya
//
//  Created by tesla on 2017/9/12.
//

import Foundation

public extension String {
    var md5: String {
        if let data = base.data(using: .utf8, allowLossyConversion: true) {
            
            let message = data.withUnsafeBytes { bytes -> [UInt8] in
                return Array(UnsafeBufferPointer(start: bytes, count: data.count))
            }
            
            let MD5Calculator = MD5(message)
            let MD5Data = MD5Calculator.calculate()
            
            var MD5String = String()
            for c in MD5Data {
                MD5String += String(format: "%02x", c)
            }
            return MD5String
            
        } else {
            return base
        }
    }
}
