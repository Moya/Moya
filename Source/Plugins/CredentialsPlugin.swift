import Foundation

/// Provides each request with optional NSURLCredentials.
public final class CredentialsPlugin: Plugin {

    public typealias CredentialClosure = MoyaTarget -> NSURLCredential?
    let credentialsClosure: CredentialClosure

    public init(credentialsClosure: CredentialClosure) {
        self.credentialsClosure = credentialsClosure
    }

    // MARK: Plugin
    
    public func willSendRequest(request: MoyaRequest, target: MoyaTarget) {
        if let credentials = credentialsClosure(target) {
            request.authenticate(usingCredential: credentials)
        }
    }
    public func didReceiveResponse(data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?, target: MoyaTarget) {
        return
    }
}