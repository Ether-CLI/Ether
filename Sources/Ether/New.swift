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

import Console
import Helpers
import Foundation

public final class New: Command {
    public let id = "new"
    
    public let help: [String] = [
        "Create new projects"
    ]
    
    public let signature: [Argument] = [
        Value(name: "name", help: [
            "The name of the new project"
        ]),
        Option(name: "executable", short: "e", help: [
            "Creates an executable SPM project"
        ]),
        Option(name: "package", short: "p", help: [
            "Creates an SPM package"
        ]),
        Option(name: "template", help: [
            "Creates a project starting with a previously saved template"
        ])
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        let newProjectBar = console.loadingBar(title: "Generating Project")
        newProjectBar.start()
        
        let executable = try newExecutable(arguments: arguments)
        let template = try newFromTemplate(arguments: arguments)
        if !executable && !template {
            try newPackage(arguments: arguments)
        }
        
        newProjectBar.finish()
    }
    
    func newExecutable(arguments: [String]) throws -> Bool {
        if let _ = arguments.option("executable") {
            let name = try value("name", from: arguments)
            let script = "mkdir \(name); cd \(name); swift package init --type=executable"
            _ = try console.backgroundExecute(program: "bash", arguments: ["-c", script])
            return true
        }
        return false
    }
    
    func newFromTemplate(arguments: [String]) throws -> Bool {
        if let template = arguments.option("template") {
            let name = try value("name", from: arguments)
            let manager = FileManager.default
            
            if #available(OSX 10.12, *) {
                let directoryName = manager.homeDirectoryForCurrentUser.absoluteString
                let templatePath = String("\(directoryName)Library/Application Support/Ether/Templates/\(template)".dropFirst(7))
                let current = manager.currentDirectoryPath
                shell(command: "/bin/cp", "-a", "\(templatePath)", "\(current)/\(name)")
            } else {
                throw EtherError.fail("This command is not supported in macOS versions older then 10.12")
            }
            return true
        }
        return false
    }
    
    func newPackage(arguments: [String]) throws {
        let name = try value("name", from: arguments)
        let script = "mkdir \(name); cd \(name); swift package init"
        _ = try console.backgroundExecute(program: "bash", arguments: ["-c", script])
    }
}
