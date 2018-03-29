//// The MIT License (MIT)
////
//// Copyright (c) 2017 Caleb Kleveter
////
//// Permission is hereby granted, free of charge, to any person obtaining a copy
//// of this software and associated documentation files (the "Software"), to deal
//// in the Software without restriction, including without limitation the rights
//// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//// copies of the Software, and to permit persons to whom the Software is
//// furnished to do so, subject to the following conditions:
////
//// The above copyright notice and this permission notice shall be included in all
//// copies or substantial portions of the Software.
////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//// SOFTWARE.
//
//// REGEX: \\.Package\\(url\\:\\s?\\\"https\\:\\/\\/github\\.com([\\d\\w\\:\\/\\.\\@\\-]+)\\.git\\\"\\,([\\d\\w\\s\\:])+\\)\\,?
//
//import Console
//import Helpers
//import Foundation
//import Core
//
//public final class VersionLatest: Command {
//    public let id = "latest"
//    public let baseURL = "https://packagecatalog.com/data/package"
//    
//    public var help: [String] = [
//        "Updates all packeges to the latest version"
//    ]
//    
//    public var signature: [Argument] = [
//        Option(name: "xcode", short: "x", help: [
//            "Regenerate Xcode project after updating package versions"
//        ])
//    ]
//    
//    public let console: ConsoleProtocol
//    public let client = PackageJSONFetcher()
//    
//    public init(console: ConsoleProtocol) {
//        self.console = console
//    }
//    
//    public func run(arguments: [String]) throws {
//        let updateBar = console.loadingBar(title: "Updating Package Versions")
//        updateBar.start()
//        
//        let fileManager = FileManager.default
//        let manifest = try Manifest.current.get()
//        let nsManifest = NSMutableString(string: manifest)
//        let versionPattern = try NSRegularExpression(pattern: "(.package\\(url:\\s*\".*?\\.com\\/(.*?)\\.git\",\\s*)(.*?)(\\),?\\n)", options: [])
//        let matches = versionPattern.matches(in: manifest, options: [], range: NSMakeRange(0, manifest.utf8.count))
//        let packageNames = matches.map { match -> String in
//            let name = versionPattern.replacementString(for: match, in: manifest, offset: 0, template: "$2")
//            return name
//        }
//        let packageVersions = try packageNames.map { name -> String in
//            return try Manifest.current.getPackageData(for: name).version
//        }
//        
//        try zip(packageVersions, packageNames).forEach { (arg) in
//            let (version, name) = arg
//            let pattern = try NSRegularExpression(pattern: "(.package\\(url:\\s*\".*?\\.com\\/\(name)\\.git\",\\s*)(\\.?\\w+(\\(|:)\\s*\"[\\w\\.]+\"\\)?)(\\))", options: [])
//            pattern.replaceMatches(in: nsManifest, options: [], range: NSMakeRange(0, nsManifest.length), withTemplate: "$1.exact(\"\(version)\"))")
//        }
//        
//        try String(nsManifest).data(using: .utf8)?.write(to: URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift")!)
//        _ = try console.backgroundExecute(program: "swift", arguments: ["package", "update"])
//        _ = try console.backgroundExecute(program: "swift", arguments: ["package", "resolve"])
//        
//        updateBar.finish()
//        
//        if let _ = arguments.options["xcode"] {
//            let xcodeBar = console.loadingBar(title: "Generating Xcode Project")
//            xcodeBar.start()
//            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "generate-xcodeproj"])
//            xcodeBar.finish()
//            try console.execute(program: "/bin/sh", arguments: ["-c", "open *.xcodeproj"], input: nil, output: nil, error: nil)
//        }
//    }
//}
