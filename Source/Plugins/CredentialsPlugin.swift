import Foundation
import Result

/// Provides each request with optional NSURLCredentials.
public final class CredentialsPlugin: PluginType {

    public typealias CredentialClosure = (TargetType) -> URLCredential?
    let credentialsClosure: CredentialClosure

    public init(credentialsClosure: @escaping CredentialClosure) {
        self.credentialsClosure = credentialsClosure
    }

    // MARK: Plugin

    public func willSendRequest(_ request: RequestType, target: TargetType) {
        if let credentials = credentialsClosure(target) {
            _ = request.authenticate(usingCredential: credentials)
        }
    }

    public func didReceiveResponse(_ result: Result<Moya.Response, Moya.Error>, target: TargetType) {

    }
}
