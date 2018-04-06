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
import Console
import Command
import Async

public final class VersionAll: Command {
    public var arguments: [CommandArgument] = []
    
    public var options: [CommandOption] = []
    
    public var help: [String] = ["Outputs the name of each package installed and its version"]
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        context.console.output("Getting Package Data...", style: .success)
        
        let pins = try Manifest.current.resolved().object.pins
        
        pins.forEach { package in
            context.console.output(package.package, style: .success, newLine: false)
            let version: String
            
            if let number = package.state.version {
                version = "v\(number)"
            } else if let branch = package.state.branch {
                version = branch
            } else {
                version = package.state.revision
            }
            
            context.console.print(version)
        }
        
        return context.container.eventLoop.newSucceededFuture(result: ())
    }
}
