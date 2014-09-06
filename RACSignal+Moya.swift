//
//  RACSignal+Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-09-06.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

let MoyaErrorDomain = "Moya"

public enum MoyaErrorCode: Int {
    case ImageMapping = 0
    case JSONMapping
    case StringMapping
}

public extension RACSignal {
    public func mapImage() -> RACSignal {
        return self.tryMap({ (object, error) -> AnyObject! in
            var image: UIImage?
            if let data = object as? NSData {
                image = UIImage(data: data)
            }
            
            if image == nil && error != nil {
                error.memory = NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.ImageMapping.toRaw(), userInfo: ["data": object])
            }
            
            return image
        })
    }
    
    public func mapImageOnBackgroundScheduler() -> RACSignal {
        return self.deliverOn(RACScheduler(priority: RACSchedulerPriorityDefault))
            .mapImage()
            .deliverOn(RACScheduler.mainThreadScheduler())
    }
    
    public func mapJSON() -> RACSignal {
        return self.tryMap({ (object, error) -> AnyObject! in
            var json: AnyObject?
            if let data = object as? NSData {
                json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: error)
            }
            
            if json == nil && error != nil && error.memory == nil {
                var userInfo: [NSObject : AnyObject]?
                if object != nil {
                    userInfo = ["data": object]
                }
                
                error.memory = NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.JSONMapping.toRaw(), userInfo: userInfo)
            }
            
            return json
        })
    }
    
    public func mapString() -> RACSignal {
        return self.tryMap({ (object, error) -> AnyObject! in
            var string: String?
            
            if let data = object as? NSData {
                string = NSString(data: data, encoding: NSUTF8StringEncoding)
            }
            
            if string == nil {
                var userInfo: [NSObject : AnyObject]?
                if object != nil {
                    userInfo = ["data": object]
                }
                
                error.memory = NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.StringMapping.toRaw(), userInfo: userInfo)
            }
            
            return string
        })
    }
}
