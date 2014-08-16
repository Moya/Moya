//
//  MoyaTests.swift
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
        var endpoints: [Endpoint]?
        beforeSuite {
            let bundle = NSBundle(forClass: self.dynamicType)
            
            let endpoints = [
                Endpoint(URL: "http://rdjpg.com/300/200", sampleResponse: {
                    let path = bundle.pathForResource("300_200", ofType: "png")
                    let data = NSData(contentsOfFile: path)
                    return data
                })
            ]
        }
        
        describe("when stubbing endpoints", { () -> () in
            var provider: MoyaProvider?
            beforeEach({
                provider = MoyaProvider(endpoints: endpoints!)
            })
            
            it("passes returns stubbed data") {
                var response: AnyObject?
                provider!.request("http://rdjpg.com/300/200", completion: { (object: AnyObject?) -> () in
                    response = object
                })
            }
        })
        
        describe("when accessing the network", { () -> () in
            var provider: MoyaProvider?
            beforeEach({ () -> () in
                provider = MoyaProvider(endpoints: endpoints!)
            })
        })
    }
}
