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

final class TemplateList: Command {
    var arguments: [CommandArgument] = []
    var options: [CommandOption] = []
    
    var help: [String] = ["Lists all saved project templates"]
    
    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        
        let user = try Process.execute("whoami")
        try FileManager.default.createDirectory(
            at: URL(string: "file:/Users/\(user)/Library/Application%20Support/Ether/Templates")!,
            withIntermediateDirectories: true,
            attributes: [:]
        )
        
        let projects = try Process.execute("ls", "/Users/\(user)/Library/Application Support/Ether/Templates/")
        for project in projects.split(separator: "\n").map(String.init) {
            context.console.info("- ", newLine: false)
            context.console.print(project)
        }
        
        return context.container.eventLoop.newSucceededFuture(result: ())
    }
}
