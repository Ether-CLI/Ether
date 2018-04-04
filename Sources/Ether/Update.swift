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
import Command
import Async

public final class Update: Command {
    public var arguments: [CommandArgument] = []
    
    public var options: [CommandOption] = [
        CommandOption.flag(name: "ether", short: "e", help: ["Updates Ether CLI"]),
        CommandOption.flag(name: "xcode", short: "x", help: ["Regenerate and open the Xcode project after updating packages"])
    ]
    
    public var help: [String] = ["Updates a project's dependencies."]
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        return context.container.eventLoop.newSucceededFuture(result: ())
    }
}

//    public func run(arguments: [String]) throws {
//        if let _ = arguments.option("self") {
//            let updateBar = console.loadingBar(title: "Updating Ether")
//            updateBar.start()
//            _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "curl https://raw.githubusercontent.com/calebkleveter/Ether/master/install.sh | bash"])
//            updateBar.finish()
//            self.printEtherArt()
//        } else {
//            console.output("This may take some time...", style: .info, newLine: true)
//            
//            let updateBar = console.loadingBar(title: "Updating Packages")
//            updateBar.start()
//            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", ".build"])
//            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "update"])
//            _ = try console.backgroundExecute(program: "swift", arguments: ["package", "resolve"])
//            _ = try console.backgroundExecute(program: "swift", arguments: ["build"])
//            updateBar.finish()
//            
//            if let _ = arguments.options["xcode"] {
//                let xcodeBar = console.loadingBar(title: "Generating Xcode Project")
//                xcodeBar.start()
//                _ = try console.backgroundExecute(program: "swift", arguments: ["package", "generate-xcodeproj"])
//                xcodeBar.finish()
//                try console.execute(program: "/bin/sh", arguments: ["-c", "open *.xcodeproj"], input: nil, output: nil, error: nil)
//            }
//        }
//    }
//
//    private func printEtherArt() {
//        let etherArt = """
//          | • |
//          | • |
//          | • |
//         /     \\
//        /       \\
//        """
//
//        let characterColors: [Character: ConsoleColor] = [
//            "•": .green
//        ]
//
//        for character in console.center(etherArt) {
//            let style: ConsoleStyle
//
//            if let color = characterColors[character] {
//                style = .custom(color)
//            } else {
//                style = .plain
//            }
//
//            console.output("\(character)", style: style, newLine: false)
//        }
//
//        console.print()
//        console.print()
//        console.output(console.center("Thanks for Updating Ether!"), style: .plain, newLine: true)
//    }
//
//}
