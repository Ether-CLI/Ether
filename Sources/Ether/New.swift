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
import Command
import Console
import Async

public final class New: Command {
    public var arguments: [CommandArgument] = [
        CommandArgument.argument(name: "name", help: ["The name of the new project"])
    ]
    
    public var options: [CommandOption] = [
        CommandOption.flag(name: "executable", short: "e", help: ["Creates an executable SPM project"]),
        CommandOption.flag(name: "package", short: "p", help: ["(default) Creates an SPM package"]),
        CommandOption.value(name: "template", help: ["Creates a project with a previously saved template"])
    ]
    
    public var help: [String] = ["Creates a new project"]
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let newProject = context.console.loadingBar(title: "Generating Project")
        _ = newProject.start(on: context.container)

        let executable = try newExecutable(from: context)
        let template = try newFromTemplate(using: context)
        if !executable && !template {
            try newPackage(from: context)
        }

        newProject.succeed()
        return context.container.eventLoop.newSucceededFuture(result: ())
    }
    
    func newExecutable(from context: CommandContext) throws -> Bool {
        if let _ = context.options["executable"] {
            let name = try context.argument("name")
            let script = "mkdir \(name); cd \(name); swift package init --type=executable; ether clean-manifest"
            _ = try Process.execute("bash", ["-c", script])
            return true
        }
        return false
    }
    
    func newFromTemplate(using context: CommandContext) throws -> Bool {
        if let template = context.options["template"] {
            let name = try context.argument("name")
            let manager = FileManager.default

            if #available(OSX 10.12, *) {
                let directoryName = manager.homeDirectoryForCurrentUser.absoluteString
                let templatePath = String("\(directoryName)Library/Application Support/Ether/Templates/\(template)".dropFirst(7))
                let current = manager.currentDirectoryPath
                _ = try Process.execute("cp", ["-a", "\(templatePath)", "\(current)/\(name)"])
            } else {
                fatalError("This command is not supported in macOS versions older then 10.12")
                // throw EtherError.fail("This command is not supported in macOS versions older then 10.12")
            }
            return true
        }
        return false
    }
    
    func newPackage(from context: CommandContext) throws {
        let name = try context.argument("name")
        let script = "mkdir \(name); cd \(name); swift package init; ether clean-manifest"
        _ = try Process.execute("bash", ["-c", script])
    }
}
