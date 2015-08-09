//
//  ReactiveMoyaError.swift
//  Moya
//
//  Created by Justin Makaila on 6/28/15.
//  Copyright © 2015 Moya. All rights reserved.
//

import Foundation

public let ReactiveMoyaErrorDomain = "ReactiveMoya"

public enum ReactiveMoyaError {
    public enum ErrorCode: Int {
        case ResponseMapping = -1
        case ImageMapping
        case JSONMapping
        case StringMapping
        case StatusCode
        case Data
    }
    
    case ResponseMapping(AnyObject)
    case ImageMapping(AnyObject)
    case JSONMapping(AnyObject)
    case StringMapping(AnyObject)
    case StatusCode(AnyObject)
    case Data(AnyObject)
    
    public func errorCode() -> Int {
        switch self {
        case ResponseMapping:
            return ErrorCode.ResponseMapping.rawValue
        case ImageMapping:
            return ErrorCode.ImageMapping.rawValue
        case JSONMapping:
            return ErrorCode.JSONMapping.rawValue
        case StringMapping:
            return ErrorCode.StringMapping.rawValue
        case StatusCode:
            return ErrorCode.StatusCode.rawValue
        case Data:
            return ErrorCode.Data.rawValue
        }
    }
    
    public func userInfo() -> [NSObject: AnyObject] {
        switch self {
        case .ResponseMapping(let object):
            return ["data": object]
        case .ImageMapping(let object):
            return ["data": object]
        case .JSONMapping(let object):
            return ["data": object]
        case .StringMapping(let object):
            return ["data": object]
        case .StatusCode(let object):
            return ["data": object]
        case .Data(let object):
            return ["data": object]
        }
    }
    
    public func toError() -> NSError {
        return NSError(domain: ReactiveMoyaErrorDomain, code: errorCode(), userInfo: userInfo())
    }
}
