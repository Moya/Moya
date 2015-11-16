import Foundation

/// Provides each request with optional NSURLCredentials.
public final class CredentialsPlugin: Plugin {

    public typealias CredentialClosure = TargetType -> NSURLCredential?
    let credentialsClosure: CredentialClosure

    public init(credentialsClosure: CredentialClosure) {
        self.credentialsClosure = credentialsClosure
    }

    // MARK: Plugin
    
    public func willSendRequest(request: Request, target: TargetType) {
        if let credentials = credentialsClosure(target) {
            request.authenticate(usingCredential: credentials)
        }
    }

    public func didReceiveResponse(data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?, target: TargetType) {
        return
    }
}