import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking

public typealias URLRequest = FoundationNetworking.URLRequest
public typealias URLCredential = FoundationNetworking.URLCredential
public typealias HTTPURLResponse = FoundationNetworking.HTTPURLResponse
internal typealias URLSessionConfiguration = FoundationNetworking.URLSessionConfiguration

#endif

#if os(Linux)
import CDispatch

internal var NSEC_PER_SEC: UInt64 { CDispatch.NSEC_PER_SEC }

#endif
