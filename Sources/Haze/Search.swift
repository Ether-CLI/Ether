import Helpers
import Console
import Foundation
import Core

public final class Search: Command {
    public let id = "search"
    
    public let baseURL = "https://packagecatalog.com/api/search/"
    public let sort = "chart"
    public let results = "items"
    
    public var help: [String] = [
        "Searches for availible packages."
    ]
    
    public var signature: [Argument] = [
        Value(name: "name", help: [
            "The name of the package to search for."
        ]),
        Option(name: "max-results", help: [
            "The maximum number of results that will be returned.",
            "This defaults to 20."
        ]),
        Option(name: "sort", help: [
            "The sorting method to use:",
            "moststarred (Most Starred)",
            "leaststarred (Least Starred)",
            "mostrecent (Most Recent)",
            "leastrecent (Least Recent)",
            "The default value is moststarred."
        ])
    ]
    
    public let console: ConsoleProtocol
    public let client = PackageJSONFetcher()
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        let searchingBar = console.loadingBar(title: "Searching")
        searchingBar.start()
        
        let name = try value("name", from: arguments)
        let maxResults = arguments.options["max-results"] ?? "20"
        let sortMethod = arguments.options["sort"] ?? "moststarred"
        
        func fail(_ message: String) -> Error {
            searchingBar.fail()
            return HazeError.fail(message)
        }
        
        var totalResults: Int?
        var maxedResults: Bool?
        var packages: [(name: String?, description: String?)]?
        
        let (json,error) = try Portal<(JSON?,Error?)>.open({ (portal) in
            self.client.get(from: "https://packagecatalog.com/api/search/\(name)", withParameters: [self.sort: sortMethod, self.results: maxResults], { (json, error) in
                portal.close(with: (json,error))
            })
        })
        
        guard let data = json?["data"] as? JSON else { throw fail("Bad JSON key") }
        guard let hits = data["hits"] as? JSON else { throw fail("Bad JSON key") }
        guard let results = hits["hits"] as? [JSON] else { throw fail("Bad JSON key") }
        
        packages = try results.map { (result) -> (name: String?, description: String?) in
            guard let source = result["_source"] as? JSON else { throw fail("Bad JSON key") }
            return (name: source["package_full_name"] as? String, description: source["description"] as? String)
        }
        
        maxedResults = Int(String(describing: hits["total"] ?? 0 as AnyObject))! > Int(maxResults)!
        totalResults = Int(String(describing: hits["total"] ?? 0 as AnyObject))
        
        if let error = error {
            self.console.output("Error: \(error)", style: .error, newLine: true)
            searchingBar.fail()
        }
        searchingBar.finish()
        
        self.console.output("Total results: \(totalResults ?? 0)", style: .info, newLine: true)
        
        if let maxedResults = maxedResults {
            if maxedResults {
                self.console.output("Not all results are shown.", style: .info, newLine: true)
            }
        }
        if let packages = packages {
            for package in packages {
                self.console.output("\(package.name ?? "N/A"): \(package.description ?? "N/A")", style: .info, newLine: true)
            }
        }
    }
}
