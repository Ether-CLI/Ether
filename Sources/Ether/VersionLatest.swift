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
import Manifest
import Helpers
import Command
import Vapor

public final class VersionLatest: Command {
    public var arguments: [CommandArgument] = []
    
    public var options: [CommandOption] = [
        CommandOption.flag(name: "xcode", short: "x", help: ["Regenerate Xcode project after updating package versions"])
    ]
    
    public var help: [String] = ["Updates all packeges to the latest version"]
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let updating = context.console.loadingBar(title: "Updating Version Versions")
        _ = updating.start(on: context.container)
        
        let regex = try NSRegularExpression(pattern: ".*?\\.com\\/(.*?)\\.git", options: [])
        let client = try context.container.make(Client.self)
        
        guard let token = try Configuration.get().accessToken else {
            throw EtherError(
                identifier: "noAccessToken",
                reason: "No access token in configuration. Run `ether config access-token <TOKEN>`. The token should have permissions to access public repositories"
            )
        }
        
        let packageNames = try Manifest.current.dependencies().compactMap { dependency -> (fullName: String, url: String)? in
            guard let result = regex.firstMatch(in: dependency.url, options: [], range: NSMakeRange(0, dependency.url.utf8.count)) else { return nil }
            return (regex.replacementString(for: result, in: dependency.url, offset: 0, template: "$1"), dependency.url)
        }
        let versions = packageNames.map { $0.fullName }.map { name in
            return client.get("https://package.vapor.cloud/packages/\(name)/releases", headers: ["Authorization": "Bearer \(token)"]).flatMap { response in
                return try response.content.decode([String].self)
            }.map { releases in releases.first }
        }.flatten(on: context.container)
        
        return versions.map(to: Void.self) { versions in
            try zip(packageNames, versions).forEach { packageVersion in
                let (names, version) = packageVersion
                let dependency = try Manifest.current.dependency(withURL: names.url)
                if let version = version {
                    dependency?.version = .from(version)
                }
                try dependency?.save()
            }
            
            _ = try Process.execute("swift", "package", "update")
            updating.succeed()
            
            if let _ = context.options["xcode"] {
                let xcodeBar = context.console.loadingBar(title: "Generating Xcode Project")
                _ = xcodeBar.start(on: context.container)
                
                _ = try Process.execute("swift", "package", "generate-xcodeproj")
                xcodeBar.succeed()
                _ = try Process.execute("sh", "-c", "open *.xcodeproj")
            }
        }
    }
}
