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

public final class Update: Command {
    public var arguments: [CommandArgument] = []
    
    public var options: [CommandOption] = [
        CommandOption.flag(name: "ether", short: "e", help: ["Updates Ether CLI"]),
        CommandOption.flag(name: "xcode", short: "x", help: ["Regenerate and open the Xcode project after updating packages"])
    ]
    
    public var help: [String] = ["Updates a project's dependencies."]
    
    public init() {}
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        if context.options["ether"] != nil {
            let updating = context.console.loadingBar(title: "Updating Ether")
            _ = updating.start(on: context.container)
            
            _ = try Process.execute("bash", ["-c", "curl https://raw.githubusercontent.com/Ether-CLI/Ether/master/install.sh | bash"])
            
            updating.succeed()
            self.printEtherArt(with: context.console)
        } else {
            context.console.output("This may take some time...", style: .info, newLine: true)

            let updating = context.console.loadingBar(title: "Updating Packages")
            _ = updating.start(on: context.container)
            
            _ = try Process.execute("swift", ["package", "update"])
            _ = try Process.execute("swift", ["package", "resolve"])
            
            updating.succeed()

            let config = try Configuration.get()
            try config.commit(with: config.updateCommit, on: context, replacements: [])
            
            if context.options["xcode"] != nil {
                let xcode = context.console.loadingBar(title: "Generating Xcode Project")
                _ = xcode.start(on: context.container)
                
                _ = try Process.execute("swift", ["package", "generate-xcodeproj"])
                
                xcode.succeed()
                _ = try Process.execute("/bin/sh", ["-c", "open *.xcodeproj"])
            }
        }
        
        return context.container.future()
    }
    
    private func printEtherArt(with console: Console) {
        let etherArt = """
          | • |
          | • |
          | • |
         /     \\
        /       \\
        """

        let characterColors: [Character: ConsoleColor] = [
            "•": .green
        ]

        for character in console.center(etherArt) {
            let style: ConsoleStyle

            if let color = characterColors[character] {
                style = ConsoleStyle(color: color)
            } else {
                style = .plain
            }

            console.output("\(character)", style: style, newLine: false)
        }

        console.print()
        console.print()
        console.output(console.center("Thanks for Updating Ether!"), style: .plain, newLine: true)
    }
}
