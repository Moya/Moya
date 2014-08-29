//
//  MoyaProviderSpec.swift
//  MoyaTests
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import UIKit
import Quick
import Nimble
import Moya

class MoyaProviderSpec: QuickSpec {
    override func spec() {
        describe("valid enpoints") {
            describe("with stubbed data") {
                
                describe("a provider", { () -> () in
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider(endpointsClosure: endpointsClosure, stubResponses: true)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target, completion: { (object, error) in
                            if let data = object as? NSData {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        expect{message}.toEventually(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)), timeout: 1, pollInterval: 0.1)
                    }
                    
                    it("returns stubbed data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target, completion: { (object, error) in
                            if let data = object as? NSData {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        expect{message}.toEventually(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)), timeout: 1, pollInterval: 0.1)
                    }
                })
                
                describe("a reactive provider", { () -> () in
                    var provider: ReactiveMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveMoyaProvider(endpointsClosure: endpointsClosure, stubResponses: true)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target).subscribeNext({ (object) -> Void in
                            if let data = object as? NSData {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        expect{message}.toEventuallyNot(beNil(), timeout: 1, pollInterval: 0.1)
                    }
                    
                    it("returns correct data for user profile request") {
                        var response: NSDictionary?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeNext({ (object) -> Void in
                            if let data = object as? NSData {
                                response = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        let sampleResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(sampleData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                        expect{response}.toEventuallyNot(beNil(), timeout: 1, pollInterval: 0.1)
                    }
                })
            }
        }
    }
}
