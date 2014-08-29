//
//  MoyaProviderIntegrationTests.swift
//  MoyaTests
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import UIKit
import Quick
import Nimble
import Moya

class MoyaProviderIntegrationTests: QuickSpec {
    override func spec() {
        describe("valid enpoints") {
            describe("with live data") {
                describe("a provider", { () -> () in
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider(endpointsClosure: endpointsClosure)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target, completion: { (object, error) in
                            if let data = object as? NSData {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        expect{message}.toEventuallyNot(beNil(), timeout: 10, pollInterval: 0.1)
                    }
                    
                    it("returns stubbed data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target, completion: { (object, error) in
                            if let data = object as? NSData {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        expect{message}.toEventually(beNil(), timeout: 10, pollInterval: 0.1)
                    }
                })
                
                describe("a reactive provider", { () -> () in
                    var provider: ReactiveMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveMoyaProvider(endpointsClosure: endpointsClosure)
                    }
                    
                    it("returns some data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target, completion: { (object, error) in
                            if let data = object as? NSData {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        expect{message}.toEventuallyNot(beNil(), timeout: 10, pollInterval: 0.1)
                    }
                    
                    it("returns some data for user profile request") {
                        var response: NSDictionary?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target, completion: { (object, error) in
                            if let data = object as? NSData {
                                response = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        let sampleResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(sampleData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                        expect{response}.toEventuallyNot(beNil(), timeout: 10, pollInterval: 0.1)
                    }
                })
            }
        }
    }
}
