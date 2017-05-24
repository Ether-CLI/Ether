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

public let CKNetworkingErrorDomain = "com.caleb-kleveter.Haze.NetworkingError"
public let MissingHTTPResponseError: Int = 0

public typealias JSON = [String: AnyObject]
public typealias FetchCompletion = (JSON?, HTTPURLResponse?, DataTaskError?) -> Void

public enum DataTaskError: Error {
    case badStatusCode(Int)
    case cannotCastToHTTPURLResponse(NSError)
    case dataTaskError(Error)
    case noData
    case jsonSerializationError(Error)
    case noJson
}

public protocol JSONInitable {
    init(json: JSON)
}

public protocol APIClient {
    var configuration: URLSessionConfiguration { get }
    var session: URLSession { get }
    
    func dataTask(with request: URLRequest, endingWith completion: @escaping FetchCompletion) -> URLSessionDataTask
}

extension APIClient {
    public func dataTask(with request: URLRequest, endingWith completion: @escaping FetchCompletion) -> URLSessionDataTask {
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard let resp = response as? HTTPURLResponse else {
                let userInfo = [
                    NSLocalizedDescriptionKey: NSLocalizedString("Missing HTTP Response", comment: "")
                ]
                
                let error = NSError(domain: CKNetworkingErrorDomain, code: MissingHTTPResponseError, userInfo: userInfo)
                completion(nil, nil, DataTaskError.cannotCastToHTTPURLResponse(error))
                return
            }
            
            if resp.statusCode >= 200 && resp.statusCode < 300 {
                if error == nil {
                    if data != nil {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? JSON
                            if let json = json {
                                completion(json, resp, nil)
                            } else {
                                completion(nil, nil, .noJson)
                                return
                            }
                        } catch let error {
                            completion(nil, nil, .jsonSerializationError(error))
                            return
                        }
                        return
                    } else {
                        completion(nil, nil, .noData)
                        return
                    }
                } else {
                    completion(nil, nil, .dataTaskError(error!))
                    return
                }
            } else {
                completion(nil, nil, .badStatusCode(resp.statusCode))
                return
            }
        }
        return task
    }
}
