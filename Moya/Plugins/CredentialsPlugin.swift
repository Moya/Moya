import Foundation
import Alamofire


/// Provides each request with optional NSURLCredentials.
public class CredentialsPlugin<Target: MoyaTarget>: Plugin<Target> {
    
    public typealias CredentialClosure = Target -> NSURLCredential?
    let credentialsClosure: CredentialClosure
    
    public init(credentialsClosure: CredentialClosure) {
        self.credentialsClosure = credentialsClosure
    }
    
    
    // MARK: PluginType
    
    public override func willSendRequest(token: Target, request: Alamofire.Request) -> Alamofire.Request {
        if let credentials = credentialsClosure(token) {
            request.authenticate(usingCredential: credentials)
        }
        return request
    }
    
    override func willSendStubbedRequest(token: Target, request: NSURLRequest) {
        // Just call the closure here to make it possible to test the 
        // credentials closure when stubbed requests are turned on
        let _ = credentialsClosure(token)
    }
    
}