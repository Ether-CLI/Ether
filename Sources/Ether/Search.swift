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

import Helpers
import Command
import Console
import Vapor

public final class Search: Command {
    public var arguments: [CommandArgument] = [
        CommandArgument.argument(name: "name", help: ["The name of the package to search for."])
    ]
    
    public var options: [CommandOption] = [
        CommandOption.value(name: "max-results", default: "20", help: [
                "The maximum number of results that will be returned.",
                "This defaults to 20."
            ])
    ]
    
    public var help: [String] = ["Searches for availible packages."]
    
    public init() {}
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let searching = context.console.loadingBar(title: "Searching")
        _ = searching.start(on: context.container)
        
        let client = try context.container.make(Client.self)
        let name = try context.argument("name")
        let maxResults = context.options["max-results"] ?? "20"
        
        guard let max = Int(maxResults), max <= 100 && max > 0 else {
            throw EtherError(identifier: "badMaxResults", reason: "`max-results` value must be an integer, less than or equal to 100, and greater than 0")
        }
        let token = try Configuration.get().token()
        
        let response = client.get("https://package.vapor.cloud/packages/search?name=\(name)&limit=\(max)", headers: ["Authorization": "Bearer \(token)"])
        return response.flatMap(to: [PackageDescription].self) { response in
            searching.succeed()
            return response.content.get([PackageDescription].self, at: "repositories")
        }.map(to: Void.self) { packages in
            packages.forEach { package in
                package.print(on: context)
                context.console.print()
            }
        }
    }
}

struct PackageDescription: Codable {
    let nameWithOwner: String
    let description: String?
    let license: String?
    let stargazers: Int?
    
    func print(on context: CommandContext) {
        if let description = self.description {
            context.console.info(nameWithOwner + ": ", newLine: false)
            context.console.print(description)
        } else {
            context.console.info(self.nameWithOwner)
        }
        
        if let license = self.license {
            context.console.print("License: " + license)
        }
        
        if let stars = self.stargazers {
             context.console.print("Stars: " + String(stars))
        }
    }
}
