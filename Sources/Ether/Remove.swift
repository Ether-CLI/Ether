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
import Helpers
import Command

public final class Remove: Command {
    public var arguments: [CommandArgument] = [
        CommandArgument.argument(name: "name", help: ["The name of the package that will be removed"])
    ]
    
    public var options: [CommandOption] = [
        CommandOption.flag(name: "xcode", short: "x", help: ["Regenerate the Xcode project after removing the package"])
    ]
    
    public var help: [String] = ["Removes a package from the manifest and uninstalls it"]
    
    public init() {}
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let removing = context.console.loadingBar(title: "Removing Dependency")
        _ = removing.start(on: context.container)
        
        let name = try context.argument("name")
        let pinCount = try Manifest.current.resolved().object.pins.count
        
        guard let url = try Manifest.current.resolved().object.pins.filter({ $0.package == name }).first?.repositoryURL else {
            throw EtherError(identifier: "pinNotFound", reason: "No package was found with the name '\(name)'")
        }
        try Manifest.current.dependency(withURL: url)?.delete()
        
        _ = try Process.execute("swift", ["package", "update"])
        _ = try Process.execute("swift", ["package", "resolve"])
        
        let removed = try pinCount - Manifest.current.resolved().object.pins.count
        removing.succeed()
        
        if context.options["xcode"] != nil {
            let xcodeBar = context.console.loadingBar(title: "Generating Xcode Project")
            _ = xcodeBar.start(on: context.container)
            
            _ = try Process.execute("swift", ["package", "generate-xcodeproj"])
            xcodeBar.succeed()
            _ = try Process.execute("bash", ["-c", "open *.xcodeproj"])
        }
        
        context.console.print("📦  \(removed) packages removed")
        return context.container.eventLoop.newSucceededFuture(result: ())
    }
}
