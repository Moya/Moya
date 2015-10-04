import Foundation

/// Provides each request with optional NSURLCredentials.
public class CredentialsPlugin<Target: MoyaTarget>: Plugin<Target> {

    public typealias CredentialClosure = Target -> NSURLCredential?
    let credentialsClosure: CredentialClosure

    public init(credentialsClosure: CredentialClosure) {
        self.credentialsClosure = credentialsClosure
    }

    // MARK: Plugin
    
    public override func willSendRequest(request: MoyaRequest, provider: MoyaProvider<Target>, target: Target) {
        if let credentials = credentialsClosure(target) {
            request.authenticate(usingCredential: credentials)
        }
    }
}