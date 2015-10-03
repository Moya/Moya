import Foundation
import Alamofire


/// Provides each request with optional NSURLCredentials.
public class CredentialsPlugin<Target: MoyaTarget>: Plugin<Target> {
    
    public typealias CredentialClosure = Target -> NSURLCredential?
    let credentialsClosure: CredentialClosure
    
    public init(credentialsClosure: CredentialClosure) {
        self.credentialsClosure = credentialsClosure
    }
    
    
    // MARK: Plugin
    
    public override func willSendRequest(request: Alamofire.Request, provider: MoyaProvider<Target>, target: Target) -> Alamofire.Request {
        if let credentials = credentialsClosure(target) {
            request.authenticate(usingCredential: credentials)
        }
        return request
    }
    
}