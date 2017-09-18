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

import Helpers
import Console
import Foundation
import Core

public final class Install: Command {
    public let id = "install"
    public let baseURL = "https://packagecatalog.com/data/package/"
    
    public let signature: [Argument] = [
        Value(name: "name", help: [
            "The name of the package that will be installed"
        ]),
        Option(name: "url", help: [
            "The URL for the package"
        ]),
        Option(name: "version", help: [
            "The desired version for the package",
            "This defaults to the latest version"
        ])
    ]
    
    public var help: [String] = [
        "Installs a package into the current project"
    ]
    
    public let console: ConsoleProtocol
    public let client = PackageJSONFetcher()
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        // Create and start the progress bar
        let installingProgressBar = console.loadingBar(title: "Installing Dependancy")
        installingProgressBar.start()
        
        // Get the name of the package to install
        let name = try value("name", from: arguments)
        
        // Fetch the URL and version for the package from packagecatalog.com
        let (url, version) = try { ()throws -> (String, String) in
            var v = ""
            var u = ""
            if let version = arguments.options["version"] { v = version }
            if let url = arguments.options["url"] { u = url } else {
                if name.contains("/") {
                    let json = try self.client.get(from: self.baseURL + name, withParameters: [:])
                    
                    u = String(describing: json["ghUrl"]!) + ".git"
                    v = String(describing: json["version"]!)
                } else {
                    let json = try self.client.get(from: "https://packagecatalog.com/api/search/\(name)", withParameters: ["items": "1", "chart": "moststarred"])
                    
                    guard let data = json["data"] as? JSON else { throw fail(bar: installingProgressBar, with: "Bad JSON key: data") }
                    guard let hits = data["hits"] as? JSON else { throw fail(bar: installingProgressBar, with: "Bad JSON key: hits (1)") }
                    guard let results = hits["hits"] as? [JSON] else { throw fail(bar: installingProgressBar, with: "Bad JSON key: hits (2)") }
                    guard let source = results[0]["_source"] as? JSON else { throw fail(bar: installingProgressBar, with: "Bad JSON key: _source") }
                    
                    u = String(describing: source["git_clone_url"]!)
                    if v == "" { v = String(describing: source["latest_version"]!) }
                }
            }
            return (u,v)
        }()
        
        // Get the default FileManager instance
        let manager = FileManager.default
        
        // Check to make sure the Package.swift file exists
        if !manager.fileExists(atPath: "\(manager.currentDirectoryPath)/Package.swift") { throw EtherError.fail("There is no Package.swift file in the current directory") }
        
        // Get the data from the package manifest file
        let packageData = manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.swift")
        
        // Get the number of packages installed before the install occurs
        let oldPins = try manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.pins")?.json()?["pins"] as? [JSON]
        
        // Convert the package manifets data to a String so we can read and modify it
        guard let packageString = String(data: packageData!, encoding: .utf8) else { throw fail(bar: installingProgressBar, with: "Unable to read Package.swift") }
        
        // The package manifets contents that will be changed based off of RegEx matches
        let mutableString = NSMutableString(string: packageString)
        
        // The version numbers for the package that will be installed
        let versionNumbers = version.characters.split(separator: ".").map(String.init)
        
        // A RegEx pattern that will mach the packages in the dependencies array
        let packageInstenceRegex = try NSRegularExpression(pattern: "(\\.Package([\\w\\s\\d\\,\\:\\(\\)\\@\\-\\\"\\/\\.])+\\))(?:\\R?)", options: .anchorsMatchLines)
        
        // Check to make sure that the dependencies array exists
        if try NSRegularExpression(pattern: "(\\][\\n\\s]*,[\\n\\s]*|Package\\([\\n\\s]*name\\s*:\\s*\\\".*\\\"[\\n\\s]*,[\\n\\s]*)dependencies:[\\n\\s]*\\[(.|\\n)*\\]", options: []).matches(in: packageString, options: [], range: NSMakeRange(0, packageString.utf8.count)).count < 1 {
            
            // Create the dependencies array
            try NSRegularExpression(pattern: "(Package\\([\\n\\s]*name\\s*:\\s*\\\".*\\\"|targets\\s*:\\s*\\[(\\n|.)*\\])", options: []).replaceMatches(in: mutableString, options: [], range: NSMakeRange(0, mutableString.length), withTemplate: "$1,\n    dependencies: [\n        \n    ]")
        }
        
        // Check to see if there are packages in the dependencies array
        if packageInstenceRegex.matches(in: packageString, options: [], range: NSMakeRange(0, packageString.utf8.count)).count != 0 {
            
            // Add the new package to the dependencies array
            packageInstenceRegex.replaceMatches(in: mutableString, options: [], range: NSMakeRange(0, mutableString.length), withTemplate: "$1,\n        .Package(url: \"\(url)\", Version(\(versionNumbers[0]),\(versionNumbers[1]),\(versionNumbers[2])))\n")
        } else {
            
            // Add the new package to the dependencies array
            try NSRegularExpression(pattern: "\\],[\\s\\n]*dependencies:\\s*\\[", options: []).replaceMatches(in: mutableString, options: [], range: NSMakeRange(0, mutableString.length), withTemplate: "$1,\n        .Package(url: \"\(url)\", Version(\(versionNumbers[0]),\(versionNumbers[1]),\(versionNumbers[2])))\n")
        }
        
        do {
            // Write the updated package information to the package manifest
            try String(mutableString).data(using: .utf8)?.write(to: URL(string: "file:\(manager.currentDirectoryPath)/Package.swift")!)
            
            // Update the project's packages
            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "--enable-prefetching", "fetch"])
            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "update"])
        } catch let error {
            installingProgressBar.fail()
            throw error
        }
        
        // Close the progress bar
        installingProgressBar.finish()
        if let pins = oldPins {
            
            // Get the new number of project dependencies
            if let newPins = try manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.pins")?.json()?["pins"] as? [JSON] {
                let newPackages = newPins.count - pins.count
                
                // Output the number of packages that got installed
                console.output("📦  \(newPackages) packages installed", style: .custom(.white), newLine: true)
            }
        }
    }
}











