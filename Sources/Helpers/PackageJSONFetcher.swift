// The MIT License (MIT)
//
// Copyright (c) 2017 Caleb Kleveter
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Core

public enum GetJSONError: Error {
    case badURL(String)
    case noJSON
}

public final class PackageJSONFetcher: APIClient {
    
    public let session: URLSession
    
    public let configuration: URLSessionConfiguration
    
    public init() {
        self.configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration)
    }
    
    /// Gets the data from a URL in semi-asynchronusly.
    ///
    /// - Parameters:
    ///   - urlString: The URL the data will be fetched from.
    ///   - parameters: The URL's parameters.
    ///   - completion: The completion handler where either the JSON or Error can be accessed.
    public func get(from urlString: String, withParameters parameters: [String: String], _ completion: @escaping (APIJSON?, Error?)->()) {
        let parameterString = parameters.map({ return "\($0)=\($1)"}).joined(separator:"&")
        if let url = URL(string: urlString + "?" + parameterString) {
            let request = URLRequest(url: url)
            do {
                let (json, error) = try Portal<(APIJSON?,Error?)>.open({ (portal) in
                    self.dataTask(with: request, endingWith: { (json, reponse, error) in
                        portal.close(with: (json, error))
                    }).resume()
                })
                completion(json, error)
            } catch {}
        } else { completion(nil, GetJSONError.badURL(urlString + "?" + parameterString)) }
    }
    
    /// Synchronously fetches data from a URL
    ///
    /// - Parameters:
    ///   - url: The URL the data will be fetched from.
    ///   - parameters: The paramters for the URL.
    /// - Returns: The JSON is returned from the network request.
    /// - Throws: Any errors that occur in the Portal or in the network request.
    public func get(from url: String, withParameters parameters: [String: String])throws -> APIJSON {
        let requestResult = try Portal<(APIJSON?,Error?)>.open({ (portal) in
            self.get(from: url, withParameters: parameters, { (json, error) in portal.close(with: (json,error)) })
        })
        if let error = requestResult.1 { throw error }
        if requestResult.0 == nil { throw GetJSONError.noJSON }
        return requestResult.0!
    }
}
