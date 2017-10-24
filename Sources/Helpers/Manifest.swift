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

public class Manifest {
    public static let current = Manifest()
    private let fileManager = FileManager.default
    
    private init() {}
    
    public func getPackageName(`for` url: String)throws -> String {
        guard let resolvedURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.resolved") else {
            throw EtherError.fail("Bad path to package data. Make sure you are in the project root.")
        }
        let packageData = try Data(contentsOf: resolvedURL).json()
        
        guard let object = packageData?["object"] as? JSON,
            let pins = object["pins"] as? [JSON] else { throw EtherError.fail("Unable to read Package.resolved") }
        
        guard let package = try pins.filter({ (json) -> Bool in
            guard let repoURL = json["repositoryURL"] as? String else {
                throw EtherError.fail("Unable to read Package.resolved")
            }
            return repoURL == url
        }).first else {
            throw EtherError.fail("Unable to read Package.resolved")
        }
        
        guard let name = package["package"] as? String else {
            throw EtherError.fail("Unable to read Package.resolved")
        }
        
        return name
    }
}
