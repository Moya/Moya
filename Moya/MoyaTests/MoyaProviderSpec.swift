//
//  MoyaTests.swift
//  MoyaTests
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Quick
import Nimble
import Moya

class MoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: MoyaProvider!
        beforeEach {
            let endpoints = [Endpoint(URL: "http://rdjpg.com/300/200", {
                
            }, {
                    
            })]
            provider = MoyaProvider(endpoints: endpoints, stubResponses: true)
        }
        
        it("passes a basic assertion") {
            
        }
    }
}
