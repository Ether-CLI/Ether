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

import Manifest
import Command
import Helpers

public final class VersionSet: Command {
    public var arguments: [CommandArgument] = [
        CommandArgument.argument(name: "name", help: ["The name of the package to change the version for"]),
        CommandArgument.argument(name: "version", help: ["The version to set the specified package to. The format varies depending on the version type used"])
    ]
    
    public var options: [CommandOption] = [
        CommandOption.flag(name: "from", short: "f", help: ["(default) Sets the dependency version argument to `from: VERSION`"]),
        CommandOption.flag(name: "up-to-next-major", short: "u", help: ["Sets the dependency version argument to `.upToNextMinor(from: \"VERSION\")`"]),
        CommandOption.flag(name: "exact", short: "e", help: ["Sets the dependency version argument to `.exact(\"VERSION\")`"]),
        CommandOption.flag(name: "range", short: "r", help: ["Sets the dependency version argument to `VERSION`"]),
        CommandOption.flag(name: "branch", short: "b", help: ["Sets the dependency version argument to `.branch(\"VERSION\")`"]),
        CommandOption.flag(name: "revision", help: ["Sets the dependency version argument to `.revision(\"VERSION\")`"]),
        CommandOption.flag(name: "xcode", short: "x", help: ["Regenerate the Xcode project after updating a package's version"])
    ]
    
    public var help: [String] = ["Changes the version of a single dependency"]
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let updating = context.console.loadingBar(title: "Updating Package Version")
        _ = updating.start(on: context.container)
        
        let package = try context.argument("name")
        let version = try context.argument("version")
        let versionLitteral = try self.version(from: context.options, with: version)
        
        guard let url = try Manifest.current.resolved().object.pins.filter({ $0.package == package }).first?.repositoryURL else {
            throw EtherError(identifier: "pinNotFound", reason: "No pin entry found for package name '\(package)'")
        }
        guard let dependency = try Manifest.current.dependency(withURL: url) else {
            throw EtherError(identifier: "packageNotFound", reason: "No package found with URL '\(url)'")
        }
        dependency.version = versionLitteral
        try dependency.save()
        
        _ = try Process.execute("swift", "package", "update")
        updating.succeed()

        if let _ = context.options["xcode"] {
            let xcodeBar = context.console.loadingBar(title: "Generating Xcode Project")
            _ = xcodeBar.start(on: context.container)
            _ = try Process.execute("swift", "package", "generate-xcodeproj")
            xcodeBar.succeed()
            _ = try Process.execute("/bin/sh", "-c", "open *.xcodeproj")
        }
        
        return context.container.eventLoop.newSucceededFuture(result: ())
    }
    
    private func version(from options: [String: String], with version: String)throws -> DependencyVersionType {
        if options["exact"] != nil {
            return .exact(version)
            
        } else if options["up-to-next-major"] != nil {
            return .upToNextMajor(version)
            
        } else if options["branch"] != nil {
            return .branch(version)
            
        } else if options["revision"] != nil {
            return .revision(version)
            
        } else if options["range"] != nil {
            let pattern = try NSRegularExpression(pattern: "(.*?)(\\.\\.(?:\\.|<))(.*)", options: [])
            guard let match = pattern.firstMatch(in: version, options: [], range: version.range) else {
                throw EtherError(identifier: "badVersionStructure", reason: "The '--range' flag was passed in, but the version is not structured as a range")
            }
            let open = version.substring(at: match.range(at: 1))!
            let `operator` = version.substring(at: match.range(at: 2))!
            let close = version.substring(at: match.range(at: 3))!
            
            return .range("\"\(open)\"\(`operator`)\"\(close)\"")
        }
        
        return .from(version)
    }
}
