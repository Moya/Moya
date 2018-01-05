import Foundation

/// Represents a response to a `MoyaProvider.request`.
public final class Response: CustomDebugStringConvertible, Equatable {

    /// The status code of the response.
    public let statusCode: Int

    /// The response data.
    public let data: Data

    /// The original URLRequest for the response.
    public let request: URLRequest?

    /// The HTTPURLResponse object.
    public let response: HTTPURLResponse?

    public init(statusCode: Int, data: Data, request: URLRequest? = nil, response: HTTPURLResponse? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.request = request
        self.response = response
    }

    /// A text description of the `Response`.
    public var description: String {
        return "Status Code: \(statusCode), Data Length: \(data.count)"
    }

    /// A text description of the `Response`. Suitable for debugging.
    public var debugDescription: String {
        return description
    }

    public static func == (lhs: Response, rhs: Response) -> Bool {
        return lhs.statusCode == rhs.statusCode
            && lhs.data == rhs.data
            && lhs.response == rhs.response
    }
}

public extension Response {

    /**
     Returns the `Response` if the `statusCode` falls within the specified range.

     - parameters:
        - statusCodes: The range of acceptable status codes.
     - throws: `MoyaError.statusCode` when others are encountered.
    */
    public func filter(statusCodes: ClosedRange<Int>) throws -> Response {
        guard statusCodes.contains(statusCode) else {
            throw MoyaError.statusCode(self)
        }
        return self
    }

    /**
     Returns the `Response` if it has the specified `statusCode`.

     - parameters:
        - statusCode: The acceptable status code.
     - throws: `MoyaError.statusCode` when others are encountered.
    */
    public func filter(statusCode: Int) throws -> Response {
        return try filter(statusCodes: statusCode...statusCode)
    }

    /**
     Returns the `Response` if the `statusCode` falls within the range 200 - 299.

     - throws: `MoyaError.statusCode` when others are encountered.
    */
    public func filterSuccessfulStatusCodes() throws -> Response {
        return try filter(statusCodes: 200...299)
    }

    /**
     Returns the `Response` if the `statusCode` falls within the range 200 - 399.

     - throws: `MoyaError.statusCode` when others are encountered.
    */
    public func filterSuccessfulStatusAndRedirectCodes() throws -> Response {
        return try filter(statusCodes: 200...399)
    }

    /// Maps data received from the signal into a UIImage.
    func mapImage() throws -> Image {
        guard let image = Image(data: data) else {
            throw MoyaError.imageMapping(self)
        }
        return image
    }

    /// Maps data received from the signal into a JSON object.
    ///
    /// - parameter failsOnEmptyData: A Boolean value determining
    /// whether the mapping should fail if the data is empty.
    func mapJSON(failsOnEmptyData: Bool = true) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            if data.count < 1 && !failsOnEmptyData {
                return NSNull()
            }
            throw MoyaError.jsonMapping(self)
        }
    }

    /// Maps data received from the signal into a String.
    ///
    /// - parameter atKeyPath: Optional key path at which to parse string.
    public func mapString(atKeyPath keyPath: String? = nil) throws -> String {
        if let keyPath = keyPath {
            // Key path was provided, try to parse string at key path
            guard let jsonDictionary = try mapJSON() as? NSDictionary,
                let string = jsonDictionary.value(forKeyPath: keyPath) as? String else {
                    throw MoyaError.stringMapping(self)
            }
            return string
        } else {
            // Key path was not provided, parse entire response as string
            guard let string = String(data: data, encoding: .utf8) else {
                throw MoyaError.stringMapping(self)
            }
            return string
        }
    }

    /// Maps data received from the signal into a Decodable object.
    ///
    /// - parameter atKeyPath: Optional key path at which to parse object.
    /// - parameter using: A `JSONDecoder` instance which is used to decode data to an object.
    func map<D: Decodable>(_ type: D.Type, atKeyPath keyPath: String? = nil, using decoder: JSONDecoder = JSONDecoder()) throws -> D {
        let serializeToData: (Any) throws -> Data? = { (jsonObject) in
            guard JSONSerialization.isValidJSONObject(jsonObject) else {
                return nil
            }
            do {
                return try JSONSerialization.data(withJSONObject: jsonObject)
            } catch {
                throw MoyaError.jsonMapping(self)
            }
        }
        let jsonData: Data
        if let keyPath = keyPath {
            guard let jsonObject = (try mapJSON() as? NSDictionary)?.value(forKeyPath: keyPath) else {
                throw MoyaError.jsonMapping(self)
            }

            if let data = try serializeToData(jsonObject) {
                jsonData = data
            } else {
                let wrappedJsonObject = ["value": jsonObject]
                let wrappedJsonData: Data
                if let data = try serializeToData(wrappedJsonObject) {
                    wrappedJsonData = data
                } else {
                    throw MoyaError.jsonMapping(self)
                }
                do {
                    return try decoder.decode(DecodableWrapper<D>.self, from: wrappedJsonData).value
                } catch let error {
                    throw MoyaError.objectMapping(error, self)
                }
            }
        } else {
            jsonData = data
        }
        do {
            return try decoder.decode(D.self, from: jsonData)
        } catch let error {
            throw MoyaError.objectMapping(error, self)
        }
    }
}

private struct DecodableWrapper<T: Decodable>: Decodable {
    let value: T
}
