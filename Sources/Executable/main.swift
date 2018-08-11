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
import Vapor
import Ether

let version = "2018.08.11"

let arguments = CommandLine.arguments
if arguments.count == 2, arguments[1] == "--version" || arguments[1] == "-v" {
    let terminal = Terminal()
    terminal.output("Ether Version: \(version)", style: .info, newLine: true)
    exit(0)
}

var services = Services.default()

var commands = CommandConfig()
commands.use(Configuration(), as: "config")
commands.use(FixInstall(), as: "fix-install")
commands.use(Install(), as: "install")
commands.use(New(), as: "new")
commands.use(Remove(), as: "remove")
commands.use(Search(), as: "search")
commands.use(Update(), as: "update")
commands.use(Test(), as: "test")
commands.use(template, as: "template")
commands.use(versions, as: "version")

services.register(commands)

do {
    try Application.asyncBoot(services: services).wait().run()
} catch {
    print("Error:", error)
    exit(1)
}

