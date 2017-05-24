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
    case badURL
}

public final class PackageJSONFetcher: APIClient {
    
    public let session: URLSession
    
    public let configuration: URLSessionConfiguration
    
    public init() {
        self.configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration)
    }
    
    public func get(from urlString: String, withParameters parameters: [String: String], _ completion: @escaping (JSON?, Error?)->()) {
        let parameterString = parameters.map({ return "\($0)=\($1)"}).joined(separator:"&")
        if let url = URL(string: urlString + "?" + parameterString) {
            let request = URLRequest(url: url)
            do {
                let (json, error) = try Portal<(JSON?,Error?)>.open({ (portal) in
                    self.dataTask(with: request, endingWith: { (json, reponse, error) in
                        portal.close(with: (json, error))
                    }).resume()
                })
                completion(json, error)
            } catch {}
        } else { completion(nil, GetJSONError.badURL) }
    }
}
