import Helpers
import Console

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
        
        var error: DataTaskError?
        var totalResults: Int?
        var maxedResults: Bool?
        var packages: [(name: String?, description: String?)]?
        
        try client.get(from: "https://packagecatalog.com/api/search/\(name)", withParameters: [sort: sortMethod, results: maxResults], { (json, networkError) in
            error = networkError
            guard let json = json else { return }
            if let data = json["data"] as? JSON {
                if let hits = data["hits"] as? JSON {
                    maxedResults = Int(hits["total"] as! String)! > Int(maxResults)!
                    totalResults = Int(hits["total"] as! String)
                    if let results = hits["hits"] as? [JSON] {
                        packages = results.map { (result) -> (name: String?, description: String?) in
                            if let source = result["_source"] as? JSON {
                                return (name: source["package_full_name"] as? String, description: source["description"] as? String)
                            } else { return (name: nil, description: nil) }
                        }
                    } else { searchingBar.fail() }
                } else { searchingBar.fail() }
            } else { searchingBar.fail() }
        })
        if let error = error {
            searchingBar.fail()
            throw error
        }
        searchingBar.finish()
        
        console.output("Total results: \(totalResults ?? 0)", style: .info, newLine: true)
        
        if let maxedResults = maxedResults {
            if maxedResults {
                console.output("Not all results are shown", style: .info, newLine: true)
            }
        }
        if let packages = packages {
            for package in packages {
                console.output("\(package.name ?? "N/A"): \(package.description ?? "N/A")", style: .info, newLine: true)
            }
        }
    }
}
