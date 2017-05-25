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

public final class Remove: Command {
    public let id = "remove"
    
    public var help: [String] = [
        "Removes and uninstalls a package"
    ]
    
    public var signature: [Argument] = [
        Value(name: "name", help: [
            "The name of the package that will be removed"
        ])
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        let removingProgressBar = console.loadingBar(title: "Removing Dependency")
        removingProgressBar.start()
        
        let manager = FileManager.default
        let name = try value("name", from: arguments)
        let regex = try NSRegularExpression(pattern: "\\,?\n        \\.Package\\(url:\\s?\\\"([\\d\\-\\.\\@\\w\\/\\:])+\(name)\\.git\\\"\\,\\s?([\\w\\d\\:\\(\\)\\s\\,])+\\)", options: .caseInsensitive)
        let oldPins = try manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.pins")?.json()?["pins"] as? [JSON]
        
        if !manager.fileExists(atPath: "\(manager.currentDirectoryPath)/Package.swift") { throw EtherError.fail("There is no Package.swift file in the current directory") }
        let packageData = manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.swift")
        
        guard let packageString = String(data: packageData!, encoding: .utf8) else { throw fail(bar: removingProgressBar, with: "Unable to read Package.swift") }
        let mutableString = NSMutableString(string: packageString)
        
        if regex.matches(in: packageString, options: [], range: NSMakeRange(0, packageString.utf8.count)).count == 0 {
            throw fail(bar: removingProgressBar, with: "No packages matching the name passed in where found")
        }
        
        regex.replaceMatches(in: mutableString, options: [], range: NSMakeRange(0, mutableString.length), withTemplate: "")
        
        do {
            try String(mutableString).data(using: .utf8)?.write(to: URL(string: "file:\(manager.currentDirectoryPath)/Package.swift")!)
            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "--enable-prefetching", "fetch"])
            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "update"])
        } catch let error {
            removingProgressBar.fail()
            throw error
        }
        
        removingProgressBar.finish()
        
        if let pins = oldPins {
            if let newPins = try manager.contents(atPath: "\(manager.currentDirectoryPath)/Package.pins")?.json()?["pins"] as? [JSON] {
                let newPackages = pins.count - newPins.count
                console.output("📦  \(newPackages) packages removed", style: .custom(.white), newLine: true)
            }
        }
    }
}
