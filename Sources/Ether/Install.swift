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

import Command
import Async

public final class Install: Command {
    public var arguments: [CommandArgument] = [
        CommandArgument.argument(name: "name", help: ["The name of the package that will be installed"])
    ]
    
    public var options: [CommandOption] = [
        CommandOption.value(name: "url", short: "u", help: ["The URL for the package"]),
        CommandOption.value(name: "version", short: "v", help: [
                "The desired version for the package",
                "This defaults to the latest version"
            ]),
        CommandOption.flag(name: "xcode", short: "x", help: ["Regenerate the Xcode project after the install is complete"])
    ]
    
    public var help: [String] = ["Installs a package into the current project"]
    
    public func run(using context: CommandContext) throws -> Future<Void> {
        return context.container.eventLoop.newSucceededFuture(result: ())
    }
}

//    
//    public func run(arguments: [String]) throws {
//        console.output("Reading Package Targets...", style: .info, newLine: true)
//        
//        let fileManager = FileManager.default
//        let name = try value("name", from: arguments)
//        let installBar = console.loadingBar(title: "Installing Dependency")
//        
//        // Get package manifest and JSON data
//        guard let manifestURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift") else {
//            throw EtherError.fail("Bad path to package manifest. Make sure you are in the project root.")
//        }
//        guard let resolvedURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.resolved") else {
//            throw EtherError.fail("Bad path to package data. Make sure you are in the project root.")
//        }
//        let packageManifest = try String(contentsOf: manifestURL)
//        let mutablePackageManifest = NSMutableString(string: packageManifest)
//        let pinsCount: Int
//        
//        do {
//            let packageData = try Data(contentsOf: resolvedURL).json()
//            guard let object = packageData?["object"] as? APIJSON,
//                  let pins = object["pins"] as? [APIJSON] else { return }
//            pinsCount = pins.count
//        } catch {
//            pinsCount = 0
//        }
//        
//        // Get the names of the targets to add the dependency to
//        let targets = try Manifest.current.getTargets()
//        let useTargets: [String] = inquireFor(targets: targets)
//        
//        installBar.start()
//        
//        let packageInstenceRegex = try NSRegularExpression(pattern: "(\\.package([\\w\\s\\d\\,\\:\\(\\)\\@\\-\\\"\\/\\.])+\\)),?(?:\\R?)", options: .anchorsMatchLines)
//        let dependenciesRegex = try NSRegularExpression(pattern: "products: *\\[(?s:.*?)\\],\\s*dependencies: *\\[", options: .anchorsMatchLines)
//        
//        // Get the data for the package to install
//        let newPackageData = try Manifest.current.getPackageData(for: name)
//        let packageVersion = arguments.options["version"] ?? newPackageData.version
//        let packageUrl = arguments.options["url"] ?? newPackageData.url
//        
//        let packageInstance = "$1,\n        .package(url: \"\(packageUrl)\", .exact(\"\(packageVersion)\"))\n"
//        let depPackageInstance = "$0\n        .package(url: \"\(packageUrl)\", .exact(\"\(packageVersion)\"))"
//        
//        // Add the new package instance to the Package dependencies array.
//        if packageInstenceRegex.matches(in: packageManifest, options: [], range: NSMakeRange(0, packageManifest.utf8.count)).count > 0  {
//            packageInstenceRegex.replaceMatches(in: mutablePackageManifest, options: [], range: NSMakeRange(0, mutablePackageManifest.length), withTemplate: packageInstance)
//        } else {
//            dependenciesRegex.replaceMatches(in: mutablePackageManifest, options: [], range: NSMakeRange(0, mutablePackageManifest.length), withTemplate: depPackageInstance)
//        }
//        
//        // Write the new package manifest to the Package.swift file
//        try String(mutablePackageManifest).data(using: .utf8)?.write(to: URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift")!)
//        
//        // Update the packages.
//        _ = try console.backgroundExecute(program: "swift", arguments: ["package", "update"])
//        _ = try console.backgroundExecute(program: "swift", arguments: ["package", "resolve"])
//        
//        // Get the new package name and add it to the previously accepted targets.
//        let dependencyName = try Manifest.current.getPackageName(for: newPackageData.url)
//        for target in useTargets {
//            try mutablePackageManifest.addDependency(dependencyName, to: target)
//        }
//        
//        // Write the Package.swift file again
//        try String(mutablePackageManifest).data(using: .utf8)?.write(to: URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift")!)
//        
//        // Calculate the number of package that where installed and output it.
//        let packageData = try Data(contentsOf: resolvedURL).json()
//        guard let object = packageData?["object"] as? APIJSON,
//            let pins = object["pins"] as? [APIJSON] else { return }
//        
//        let newPackageCount = pins.count - pinsCount
//        
//        installBar.finish()
//        
//        if let _ = arguments.options["xcode"] {
//            let xcodeBar = console.loadingBar(title: "Generating Xcode Project")
//            xcodeBar.start()
//            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "generate-xcodeproj"])
//            xcodeBar.finish()
//            try console.execute(program: "/bin/sh", arguments: ["-c", "open *.xcodeproj"], input: nil, output: nil, error: nil)
//        }
//        
//        console.output("📦  \(newPackageCount) packages installed", style: .plain, newLine: true)
//    }
//    
//    /// Asks the user if they want to add a dependency to the targets in the package manifest.
//    ///
//    /// - Parameter targets: The names of the targets available.
//    /// - Returns: The names of the targets that where accepted.
//    fileprivate func inquireFor(targets: [String]) -> [String] {
//        var acceptedTargets: [String] = []
//        var index = 0
//        
//        if targets.count > 1 {
//            targetFetch: while index < targets.count {
//                let target = targets[index]
//                let response = console.ask("Would you like to add the package to the target '\(target)'? (y,n,q,?)")
//                
//                switch response {
//                case "y":
//                    acceptedTargets.append(target)
//                    index += 1
//                case "n":
//                    index += 1
//                case "q":
//                    break targetFetch
//                default: console.output("""
//                y: Add the package as a dependency to the target.
//                n: Do not add the package as a dependency to the target.
//                q: Do not add the package as a dependency to the current target or any of the following targets.
//                ?: Output this message.
//                """, style: .info, newLine: true)
//                }
//            }
//        } else {
//            acceptedTargets.append(targets[0])
//        }
//        
//        return acceptedTargets
//    }
//}
