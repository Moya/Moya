//
//  GitHubAPI.swift
//  Sample
//
//  Created by Ash Furrow on 2014-09-07.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

// MARK: - Provider setup

let endpointsClosure = { (target: GitHub, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<GitHub> in
    return Endpoint<GitHub>(URL: url(target), sampleResponse: .Success(200, target.sampleData), method: method, parameters: parameters)
}

let GitHubProvider = MoyaProvider(endpointsClosure: endpointsClosure)


// MARK: - Provider support

private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}

enum GitHub {
    case Zen
    case UserProfile(String)
    case UserRepositories(String)
}

extension GitHub : MoyaPath {
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        case .UserRepositories(let name):
            return "/users/\(name.URLEscapedString)/repos"
        }
    }
}

extension GitHub : MoyaTarget {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    var sampleData: NSData {
        switch self {
        case .Zen:
            return "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserRepositories(let name):
            return "[{\"name\": \"Repo Name\"}]".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}

extension Moya.ParameterEncoding: Equatable {
}

public func ==(lhs: Moya.ParameterEncoding, rhs: Moya.ParameterEncoding) -> Bool {
    switch (lhs, rhs) {
    case (.URL, .URL):
        return true
    case (.JSON, .JSON):
        return true
    case (.PropertyList(_), .PropertyList(_)):
        return true
    case (.Custom(_), .Custom(_)):
        return true
    default:
        return false
    }
}

public func url(route: MoyaTarget) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString!
}
