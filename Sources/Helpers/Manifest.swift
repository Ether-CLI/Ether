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
import Console
import Bits

public class Manifest {
    public static let current = Manifest()
    private let fileManager = FileManager.default
    private let client = PackageJSONFetcher()
    
    private init() {}
    
    /// Gets the package manifest for the current project.
    ///
    /// - Returns: The manifest data.
    /// - Throws: If a package manifest is not found in the current directory.
    public func get()throws -> String {
        guard let resolvedURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift") else {
            throw EtherError.fail("Unable to create URL for package manifest file.")
        }
        if !fileManager.fileExists(atPath: "\(fileManager.currentDirectoryPath)/Package.swift") {
            throw EtherError.fail("Bad path to package manifest. Make sure you are in the project root.")
        }
        
        return try String(contentsOf: resolvedURL)
    }
    
    /// Rewrites the package manifest file with a string.
    ///
    /// - Parameter string: The string the rewrite the manifest with.
    /// - Throws: Any errors that occur when createing the URL to the manifest file or in writing the manifest.
    public func write(_ string: String)throws {
        guard let manifestURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift") else {
            throw EtherError.fail("Unable to create URL for package manifest file.")
        }
        try string.data(using: .utf8)?.write(to: manifestURL)
    }
    
    /// Gets the package manifest data in JSON format.
    ///
    /// - Parameter console: The `ConsoleProtocol` instance to use to run `swift package dump-package`.
    /// - Returns: The JSON data representing the package manifest.
    /// - Throws: `EtherError.fail` if the data returned from the command cannot be converted to JSON.
    public func getJSON(withConsole console: ConsoleProtocol)throws -> APIJSON {
        guard let json = try (console.backgroundExecute(program: "swift", arguments: ["package", "dump-package"]) as Data).json() else {
            throw EtherError.fail("Unable to convert package data to JSON")
        }
        return json
    }
    
    /// Gets the name of the package that has a specefied URL by reading the `Package.resolved` file data.
    ///
    /// - Parameter url: The URL of the package that the name is to get fetched from.
    /// - Returns: The name of the package that was found.
    /// - Throws: An error is thrown if either, 1) The data in the Package.resolved file is corrupted, or 2) A package does not exist with the URL passed in
    public func getPackageName(`for` url: String)throws -> String {
        guard let resolvedURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.resolved") else {
            throw EtherError.fail("Bad path to package data. Make sure you are in the project root.")
        }
        let packageData = try Data(contentsOf: resolvedURL).json()
        
        guard let object = packageData?["object"] as? APIJSON,
            let pins = object["pins"] as? [APIJSON] else { throw EtherError.fail("Unable to read Package.resolved") }
        
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
    
    /// Gets the name of the package that has a specefied URL by reading the `Package.resolved` file data.
    ///
    /// - Parameter name: The ame of the package that the URL is to get fetched from.
    /// - Returns: The URL of the package that was found.
    /// - Throws: An error is thrown if either, 1) The data in the Package.resolved file is corrupted, or 2) A package does not exist with the name passed in
    public func getPackageUrl(`for` name: String)throws -> String {
        guard let resolvedURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.resolved") else {
            throw EtherError.fail("Bad path to package data. Make sure you are in the project root.")
        }
        let packageData = try Data(contentsOf: resolvedURL).json()
        
        guard let object = packageData?["object"] as? APIJSON,
            let pins = object["pins"] as? [APIJSON] else { throw EtherError.fail("Unable to read Package.resolved") }
        
        guard let package = try pins.filter({ (json) -> Bool in
            guard let repoURL = json["package"] as? String else {
                throw EtherError.fail("Unable to read Package.resolved")
            }
            return repoURL == name
        }).first else {
            throw EtherError.fail("No package data found for name '\(name)'")
        }
        
        guard let url = package["repositoryURL"] as? String else {
            throw EtherError.fail("Unable to read repo URL for package with name '\(name)'")
        }
        
        return url
    }
    
    /// Gets that names of all the current projects targets.
    ///
    /// - Parameter packageData: The contents of the package manifest file.
    /// - Returns: All the target names.
    /// - Throws: Any errors that occur while creating an `NSRegularExpression` to match targets against.
    public func getTargets()throws -> [String] {
        guard let resolvedURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift") else {
            throw EtherError.fail("Bad path to package data. Make sure you are in the project root.")
        }
        let packageData = try String(contentsOf: resolvedURL)
        
        let targetPattern = try NSRegularExpression(pattern: "\\.(testT|t)arget\\(\\s*name:\\s\"(.*?)\".*?(\\)|\\])\\)", options: NSRegularExpression.Options.dotMatchesLineSeparators)
        let targetMatches = targetPattern.matches(in: packageData, options: [], range: NSMakeRange(0, packageData.utf8.count))
        
        let targetNames = targetMatches.map { (match) in
            return targetPattern.replacementString(for: match, in: packageData, offset: 0, template: "$2")
        }
        
        return targetNames
    }
    
    /// Gets the pins from `Package.resolved`.
    ///
    /// - Returns: The projects package pins.
    /// - Throws: An Ether error if a `Package.resolved` file is not found, or the JSON it contains is malformed.
    public func getPins()throws -> [APIJSON] {
        guard let resolvedURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.resolved") else {
            throw EtherError.fail("Bad path to package data. Make sure you are in the project root.")
        }
        let packageData = try Data(contentsOf: resolvedURL).json()
        
        guard let object = packageData?["object"] as? APIJSON,
              let pins = object["pins"] as? [APIJSON] else {
                throw EtherError.fail("Unable to read Package.resolved")
        }
        
        return pins
    }
    
    /// Removes extra comments and white space from a package manifest.
    ///
    /// - Throws: Errors from creating maifest URL, NSRegularExpression objects, or re-writing the maifest.
    public func clean()throws {
        let manifest = try self.get()
        let lines = manifest.split(separator: "\n").map(String.init)
        
        let comment = try NSRegularExpression(pattern: " *\\/\\/ +(?!swift-tools-version).*", options: [])
        let collapse = try NSRegularExpression(pattern: " *\\.(?:library|(?:testT|t)arget)\\(", options: [])
        
        var newManifest: [String] = []
        var currentLine = ""
        var lineIndex = 0
        
        while lineIndex < lines.count {
            var line = lines[lineIndex]
            if comment.matches(in: line, options: [], range: NSMakeRange(0, line.count)).count > 0 {
                lineIndex += 1
            } else if collapse.matches(in: line, options: [], range: NSMakeRange(0, line.count)).count > 0 {
                currentLine = lines[lineIndex]
                while !line.contains(")") {
                    currentLine.append(line)
                    lineIndex += 1
                    line = lines[lineIndex]
                }
                currentLine.append(line)
                lineIndex += 1
                line = lines[lineIndex]
                
                newManifest.append(currentLine)
            } else {
                newManifest.append(line)
                lineIndex += 1
            }
        }
        
        try self.write(newManifest.joined(separator: "\n"))
    }
    
    /// Gets the URL and version of a package from the IBM package catalog API on a search URL.
    ///
    /// - Parameter name: The name of the package to get data for. If it contains a forward slash, the data will be fetched for the matching package, if it does not contain a forward slash, a search will be preformed and the first result will be used.
    /// - Returns: The URL and version of the package found.
    /// - Throws: Any errors that occur while fetching the JSON, or unwrapping the package data.
    public func getPackageData(for name: String)throws -> (url: String, version: String) {
        let packageUrl: String
        let version: String
        
        if name.contains("/") {
            let clientUrl = "https://packagecatalog.com/data/package/\(name)"
            let json = try client.get(from: clientUrl, withParameters: [:])
            guard let ghUrl = json["ghUrl"] as? String,
                let packageVersion = json["version"] as? String else {
                    throw EtherError.fail("Bad JSON")
            }
            
            packageUrl = ghUrl
            version = packageVersion
        } else {
            let clientUrl = "https://packagecatalog.com/api/search/\(name)"
            let json = try client.get(from: clientUrl, withParameters: ["items": "1", "chart": "moststarred"])
            guard let data = json["data"] as? APIJSON,
                let hits = data["hits"] as? APIJSON,
                let results = hits["hits"] as? [APIJSON],
                let source = results[0]["_source"] as? APIJSON else {
                    throw EtherError.fail("Bad JSON")
            }
            
            packageUrl = String(describing: source["git_clone_url"]!)
            version = String(describing: source["latest_version"]!)
        }
        
        return (url: packageUrl, version: version)
    }
}

extension NSMutableString {
    
    /// Adds a package dependency to a target in a package manifest file.
    ///
    /// - Parameters:
    ///   - dependency: The name of the dependency that will be added to a target.
    ///   - target: The target the dependency will be added to.
    ///   - packageData: The contents of the package manifest file.
    /// - Returns: The package manifest with the dependency added to the target.
    /// - Throws: Any errors that originate when creating an `NSRegularExpression`.
    public func addDependency(_ dependency: String, to target: String)throws {
        let targetPattern = try NSRegularExpression(pattern: "\\.(testT|t)arget\\(\\s*name:\\s\"(.*?)\".*?(\\)|\\])\\)", options: .dotMatchesLineSeparators)
        let dependenciesPattern = try NSRegularExpression(pattern: "(dependencies:\\s*\\[\\n?(\\s*).*?(\"|\\))),?\\s*\\]", options: .dotMatchesLineSeparators)
        let targetMatches = targetPattern.matches(in: String(self), options: [], range: NSMakeRange(0, self.length))
        
        guard let targetRange: NSRange = targetMatches.map({ (match) -> (name: String, range: NSRange) in
            let name = targetPattern.replacementString(for: match, in: self as String, offset: 0, template: "$2")
            let range = match.range
            return (name: name, range: range)
        }).filter({ (name: String, range: NSRange) -> Bool in
            return name == target
        }).first?.1 else { throw EtherError.fail("Attempted to add a dependency to a non-existent target") }
        
        dependenciesPattern.replaceMatches(in: self, options: [], range: targetRange, withTemplate: "$1, \"\(dependency)\"]")
    }
    
    /// Removes a package dependency from all targets in a package manifest file.
    ///
    /// - Parameters:
    ///   - dependency: The name of the dependency that will be removed from all targets.
    /// - Returns: The package manifest with the dependency added to the target.
    /// - Throws: Any errors that originate when creating an `NSRegularExpression`.
    public func removeDependency(_ dependency: String)throws {
        let dependenciesPattern = try NSRegularExpression(pattern: "(dependencies: *\\[)((\\s*(\\.\\w+)?\"\\w+\",?\\s*)*)\"\(dependency)\",?\\s*((\\s*(\\.\\w+)?\"\\w+\",?\\s*)*)(\\])", options: .dotMatchesLineSeparators)
        let range = NSMakeRange(0, self.length)
        
        dependenciesPattern.replaceMatches(in: self, options: [], range: range, withTemplate: "$1$2$5$8")
    }
}
