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

// Path: ~/Library/Application\ Support/Ether

import Console
import Foundation
import Core
import Helpers

final public class Template: Command {
    public let id = "template"
    
    public let signature: [Argument] = [
        Value(name: "template-name", help: [
            "The name used to identify the template"
        ]),
        Option(name: "github", help: [
            "Creates a GitHub repo and pushes the template to it."
        ]),
        Option(name: "remove", help: [
            "Deletes the template"
        ])
    ]
    
    public let help: [String] = [
        "Creates and stores a template for use as the starting point of a project."
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        let name = try value("template-name", from: arguments)
        let useGitHub = arguments.option("github") != nil ? true : false
        let removeTemplate = arguments.option("remove") != nil ? true : false
        let manager = FileManager.default
        let loadingBarTitle = removeTemplate ? "Deleting Template" : "Saving Template"
        
        let savingBar = console.loadingBar(title: loadingBarTitle)
        savingBar.start()
        
        if #available(OSX 10.12, *) {
            var isDir : ObjCBool = true
            let directoryName = manager.homeDirectoryForCurrentUser.absoluteString
            let defaultPath = String("\(directoryName)Library/Application Support/Ether/Templates".characters.dropFirst(7))
            let directoryExists = manager.fileExists(atPath: "\(defaultPath)/\(name)", isDirectory: &isDir)
            
            if removeTemplate {
                if !directoryExists { throw fail(bar: savingBar, with: "No template with that name exists") }
                shell(command: "/bin/rm", "-rf", "\(defaultPath)/\(name)")
            } else {
                if directoryExists { throw fail(bar: savingBar, with: "A template with that name already exists") }
                let current = manager.currentDirectoryPath + "/."
                shell(command: "/bin/cp", "-a", "\(current)", "\(defaultPath)/\(name)")
            }
        } else {
            throw fail(bar: savingBar, with: "This command is not supported in macOS versions older then 10.12")
        }
        savingBar.finish()
        
        if useGitHub {
            console.output("The GitHub flag is currently not implimented", style: .warning, newLine: true)
        }
        
    }
}
