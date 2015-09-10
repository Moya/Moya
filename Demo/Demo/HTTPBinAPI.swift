//
//  HTTPBinAPI.swift
//  Demo
//
//  Created by Alexander von Franqué on 10.09.15.
//  Copyright (c) 2015 Ash Furrow. All rights reserved.
//

import Foundation
import Moya


public enum HTTPBin {
    case BasicAuth
}

extension HTTPBin : MoyaTarget {
    
    public var baseURL: NSURL { return NSURL(string: "http://httpbin.org")! }
    public var path: String {
        switch self {
        case .BasicAuth:
            return "/basic-auth/user/passwd"
        }
    }
    
    public var method: Moya.Method {
        return .GET
    }
    public var parameters: [String: AnyObject] {
        switch self {
        default:
            return [:]
        }
    }
    
    public var sampleData: NSData {
        switch self {
        case .BasicAuth:
            return "{\"authenticated\": true, \"user\": \"user\"}".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}