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

public final class Search: Command {
    public var arguments: [CommandArgument] = [
        CommandArgument.argument(name: "name", help: ["The name of the package to search for."])
    ]
    
    public var options: [CommandOption] = [
        CommandOption.value(name: "max-results", default: "20", help: [
                "The maximum number of results that will be returned.",
                "This defaults to 20."
            ]),
        CommandOption.value(name: "sort", default: "moststarred", help: [
                "The sorting method to use:",
                "moststarred (Most Starred)",
                "leaststarred (Least Starred)",
                "mostrecent (Most Recent)",
                "leastrecent (Least Recent)",
                "The default value is moststarred."
            ])
    ]
    
    public var help: [String] = ["Searches for availible packages."]
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        return context.container.eventLoop.newSucceededFuture(result: ())
    }
}

//    
//    public func run(arguments: [String]) throws {
//        let searchingBar = console.loadingBar(title: "Searching")
//        searchingBar.start()
//        
//        let name = try value("name", from: arguments)
//        let maxResults = arguments.options["max-results"] ?? "20"
//        let sortMethod = arguments.options["sort"] ?? "moststarred"
//        
//        func fail(_ message: String) -> Error {
//            searchingBar.fail()
//            return EtherError.fail(message)
//        }
//        
//        var totalResults: Int?
//        var maxedResults: Bool?
//        var packages: [(name: String?, description: String?)]?
//        
//        let json = try self.client.get(from: self.baseURL + name, withParameters: [self.sort: sortMethod, self.results: maxResults])
//        
//        guard let data = json["data"] as? APIJSON else { throw fail("Bad JSON key") }
//        guard let hits = data["hits"] as? APIJSON else { throw fail("Bad JSON key") }
//        guard let results = hits["hits"] as? [APIJSON] else { throw fail("Bad JSON key") }
//        
//        packages = try results.map { (result) -> (name: String?, description: String?) in
//            guard let source = result["_source"] as? APIJSON else { throw fail("Bad JSON key") }
//            return (name: source["package_full_name"] as? String, description: source["description"] as? String)
//        }
//        
//        maxedResults = Int(String(describing: hits["total"] ?? 0 as AnyObject))! > Int(maxResults)!
//        totalResults = Int(String(describing: hits["total"] ?? 0 as AnyObject))
//
//        searchingBar.finish()
//        
//        self.console.output("Total results: \(totalResults ?? 0)", style: .info, newLine: true)
//        
//        if let maxedResults = maxedResults {
//            if maxedResults {
//                self.console.output("Not all results are shown.", style: .info, newLine: true)
//            }
//        }
//        if (totalResults ?? 0) > 0 {
//            console.output(String(repeating: "-", count: console.size.width), style: .info, newLine: true)
//            console.output("", style: .info, newLine: true)
//        }
//        if let packages = packages {
//            for package in packages {
//                self.console.output("\(package.name ?? "N/A"): ", style: .custom(.green), newLine: false)
//                self.console.output("\(package.description ?? "N/A")", style: .custom(.white), newLine: true)
//                console.output("", style: .info, newLine: true)
//            }
//        }
//    }
//}
