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

// REGEX: \\.Package\\(url\\:\\s?\\\"https\\:\\/\\/github\\.com([\\d\\w\\:\\/\\.\\@\\-]+)\\.git\\\"\\,([\\d\\w\\s\\:])+\\)\\,?

import Console
import Helpers
import Foundation
import Core

public final class VersionLatest: Command {
    public let id = "latest"
    public let baseURL = "https://packagecatalog.com/data/package"
    
    public var help: [String] = [
        "Updates all packeges to the latest version"
    ]
    
    public var signature: [Argument] = []
    
    public let console: ConsoleProtocol
    public let client = PackageJSONFetcher()
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        let updateBar = console.loadingBar(title: "Updating Package Versions")
        updateBar.start()
        
        let versionRegex = try NSRegularExpression(pattern: "\\.Package\\(url\\:\\s?\\\"https\\:\\/\\/github\\.com([\\d\\w\\:\\/\\.\\@\\-]+)\\.git\\\"\\,([\\d\\w\\(\\)\\:\\s\\,])+\\)\\,?", options: .anchorsMatchLines)
        
        let manager = FileManager.default
        if !manager.fileExists(atPath: "\(manager.currentDirectoryPath)/Package.swift") { throw EtherError.fail("There is no Package.swift file in the current directory") }
        let packageData = manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.swift")
        
        guard let packageString = String(data: packageData!, encoding: .utf8) else { throw fail(bar: updateBar, with: "Unable to read Package.swift") }
        let mutableString = NSMutableString(string: packageString)
        
        if versionRegex.matches(in: packageString, options: [], range: NSMakeRange(0, packageString.utf8.count)).count == 0 {
            throw fail(bar: updateBar, with: "There appear to no dependencies in you Package.swift")
        }
        
        let nsPackage = NSString(string: packageString)
        let results = versionRegex.matches(in: packageString, options: .withoutAnchoringBounds, range: NSMakeRange(0, NSString(string: packageString).length))
        let stringResults = results.map { nsPackage.substring(with: $0.range)}
        
        for result in stringResults {
            let packageName = versionRegex.stringByReplacingMatches(in: result, options: .withoutAnchoringBounds, range: NSMakeRange(0, NSString(string: result).length), withTemplate: "$1")
            let regexPackageName = packageName.replacingOccurrences(of: "/", with: "\\/")
            let replaceRegex = try NSRegularExpression(pattern: "(        \\.Package\\(url\\:\\s?\\\"https\\:\\/\\/github\\.com\(regexPackageName)\\.git\\\"\\,\\s?)([\\d\\w\\(\\)\\:\\s\\,]+)(\\))", options: .anchorsMatchLines)
            
            let (json,error) = try Portal<(JSON?,Error?)>.open({ (portal) in
                self.client.get(from: self.baseURL + packageName, withParameters: [:], { (json, error) in
                    portal.close(with: (json,error))
                })
            })
            
            if let error = error { throw fail(bar: updateBar, with: "An error occured during JSON request: \(error). URL: \(self.baseURL + packageName)") }
            guard let version = json?["version"] as? String else { throw fail(bar: updateBar, with: "Bad JSON key for \(packageName) version") }
            let versionNumbers = version.characters.split(separator: ".").map(String.init)
            let formattedVersion = "Version(\(versionNumbers[0]),\(versionNumbers[1]),\(versionNumbers[2]))"
            
            if replaceRegex.matches(in: mutableString as String, options: [], range: NSMakeRange(0, mutableString.length)).count == 0 { throw fail(bar: updateBar, with: "Error in Regex pattern") }
            replaceRegex.replaceMatches(in: mutableString, options: [], range: NSMakeRange(0, mutableString.length), withTemplate: "$1\(formattedVersion)$3")
            
            try (mutableString as String).data(using: .utf8)?.write(to: URL(string: "file:\(manager.currentDirectoryPath)/Package.swift")!)
        }
        
        updateBar.finish()
    }
}
