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
//import Console
//import Helpers
//import Foundation
//
//public final class VersonSet: Command {
//    public let id: String = "set"
//    
//    public var signature: [Argument] = [
//        Value(name: "name", help: [
//                "The name of the package to change the version for"
//            ]),
//        Value(name: "version", help: [
//                "The value for the new version. The format varies depending on the version type used"
//            ]),
//        Option(name: "xcode", short: "x", help: [
//                "Regenerate the Xcode project after updating a package's version"
//            ]),
//        Option(name: "from", short: "f", help: [
//                "Sets the dependency version argument to `from: VERSION`"
//            ]),
//        Option(name: "up-to-next-major", short: "u", help: [
//                "Sets the dependency version argument to `.upToNextMinor(from: \"VERSION\")`"
//            ]),
//        Option(name: "exact", short: "e", help: [
//                "(Default) Sets the dependency version argument to `.exact(\"VERSION\")`"
//            ]),
//        Option(name: "range", short: "r", help: [
//                "Sets the dependency version argument to `VERSION`"
//            ]),
//        Option(name: "branch", short: "b", help: [
//                "Sets the dependency version argument to `.branch(\"VERSION\")`"
//            ]),
//        Option(name: "revision", help: [
//                "Sets the dependency version argument to `.revision(\"VERSION\")`"
//            ])
//    ]
//    
//    public var help: [String] = [
//        "Changes the version of a single dependency"
//    ]
//    
//    public let console: ConsoleProtocol
//    
//    public init(console: ConsoleProtocol) {
//        self.console = console
//    }
//    
//    public func run(arguments: [String]) throws {
//        let updateBar = console.loadingBar(title: "Updating Package Version")
//        updateBar.start()
//        
//        let package = try value("name", from: arguments)
//        let version = try value("version", from: arguments)
//        let versionLitteral = versionOption(from: arguments, with: version)
//        
//        let url = try Manifest.current.getPackageUrl(for: package)
//        let manifest = try NSMutableString(string: Manifest.current.get())
//        let pattern = try NSRegularExpression(
//            pattern: "(\\,?\\n *\\.package\\(url: *\"\(url)\", *)(.*?)(\\),?\\n)",
//            options: []
//        )
//        pattern.replaceMatches(in: manifest, options: [], range: NSMakeRange(0, manifest.length), withTemplate: "$1\(versionLitteral)$3")
//        try Manifest.current.write(String(manifest))
//        
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
//        
//        console.output("\(package) version was updated", style: .plain, newLine: true)
//    }
//    
//    private func versionOption(from arguments: [String], with version: String) -> String {
//        if arguments.option("from") != nil {
//            return "from: \"\(version)\""
//        } else if arguments.option("up-to-next-major") != nil {
//            return ".upToNextMajor(from: \"\(version)\")"
//        } else if arguments.option("range") != nil {
//            return "\"\(version.dropLast(8))\"\(String(version.dropFirst(5)).dropLast(5))\"\(version.dropFirst(8))\""
//        } else if arguments.option("branch") != nil {
//            return ".branch(\"\(version)\")"
//        } else if arguments.option("revision") != nil {
//            return ".revision(\"\(version)\")"
//        }
//        return ".exact(\"\(version)\")"
//    }
//}
