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
        let installingProgressBar = console.loadingBar(title: "Installing Dependancy")
        installingProgressBar.start()
        
        let name = try value("name", from: arguments)
        let (url, version) = try { ()throws -> (String, String) in
            var v = ""
            var u = ""
            if let version = arguments.options["version"] { v = version }
            if let url = arguments.options["url"] { u = url } else {
                if name.contains("/") {
                    let (json,error) = try self.client.get(from: self.baseURL + name, withParameters: [:])
                    if let error = error { throw fail(bar: installingProgressBar, with: String(describing: error)) }
                    
                    if let json = json {
                        u = String(describing: json["ghUrl"]!) + ".git"
                        v = String(describing: json["version"]!)
                    } else { throw fail(bar: installingProgressBar, with: "No JSON found") }
                } else {
                    let (json,error) = try self.client.get(from: "https://packagecatalog.com/api/search/\(name)", withParameters: ["items": "1", "chart": "moststarred"])
                    if let error = error { throw fail(bar: installingProgressBar, with: String(describing: error)) }
                    
                    guard let data = json?["data"] as? JSON else { throw fail(bar: installingProgressBar, with: "Bad JSON key") }
                    guard let hits = data["hits"] as? JSON else { throw fail(bar: installingProgressBar, with: "Bad JSON key") }
                    guard let results = hits["hits"] as? [JSON] else { throw fail(bar: installingProgressBar, with: "Bad JSON key") }
                    guard let source = results[0]["_source"] as? JSON else { throw fail(bar: installingProgressBar, with: "Bad JSON key") }
                    
                    u = String(describing: source["git_clone_url"]!)
                    if v == "" { v = String(describing: source["latest_version"]!) }
                }
            }
            return (u,v)
        }()
        
        let versionNumbers = version.characters.split(separator: ".").map(String.init)
        let regex = try NSRegularExpression(pattern: "(\\.Package([\\w\\s\\d\\,\\:\\(\\)\\@\\-\\\"\\/\\.])+\\))(?:\\R?)", options: .anchorsMatchLines)
        
        let manager = FileManager.default
        if !manager.fileExists(atPath: "\(manager.currentDirectoryPath)/Package.swift") { throw EtherError.fail("There is no Package.swift file in the current directory") }
        let packageData = manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.swift")
        let oldPins = try manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.pins")?.json()?["pins"] as? [JSON]
        
        guard let packageString = String(data: packageData!, encoding: .utf8) else { throw fail(bar: installingProgressBar, with: "Unable to read Package.swift") }
        let mutableString = NSMutableString(string: packageString)
        
        if regex.matches(in: packageString, options: [], range: NSMakeRange(0, packageString.utf8.count)).count == 0 {
            throw fail(bar: installingProgressBar, with: "Make sure your Package.swift file is properly formatted! Does your last package have a trailing comma?")
        }
        
        regex.replaceMatches(in: mutableString, options: [], range: NSMakeRange(0, mutableString.length), withTemplate: "$1,\n        .Package(url: \"\(url)\", Version(\(versionNumbers[0]),\(versionNumbers[1]),\(versionNumbers[2])))\n")
        do {
            try String(mutableString).data(using: .utf8)?.write(to: URL(string: "file:\(manager.currentDirectoryPath)/Package.swift")!)
            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "--enable-prefetching", "fetch"])
            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "update"])
        } catch let error {
            installingProgressBar.fail()
            throw error
        }
        installingProgressBar.finish()
        if let pins = oldPins {
            if let newPins = try manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.pins")?.json()?["pins"] as? [JSON] {
                let newPackages = newPins.count - pins.count
                console.output("📦  \(newPackages) packages installed", style: .custom(.white), newLine: true)
            }
        }
    }
}











