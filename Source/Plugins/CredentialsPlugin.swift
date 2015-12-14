import Foundation
import Result

/// Provides each request with optional NSURLCredentials.
public final class CredentialsPlugin: PluginType {

    public typealias CredentialClosure = TargetType -> NSURLCredential?
    let credentialsClosure: CredentialClosure

    public init(credentialsClosure: CredentialClosure) {
        self.credentialsClosure = credentialsClosure
    }

    // MARK: Plugin
    
    public func willSendRequest(request: RequestType, target: TargetType) {
        if let credentials = credentialsClosure(target) {
            request.authenticate(usingCredential: credentials)
        }
    }
    
    public func didReceiveResponse(result: Result<Moya.Response, Moya.Error>, target: TargetType) {

    }
}
