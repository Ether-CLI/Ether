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
import Command
import Helpers
import Vapor

public final class Install: Command {
    public var arguments: [CommandArgument] = [
        CommandArgument.argument(name: "name", help: ["The name of the package that will be installed"])
    ]
    
    public var options: [CommandOption] = [
        CommandOption.value(name: "url", short: "u", help: ["The URL for the package"]),
        CommandOption.value(name: "version", short: "v", help: [
                "The desired version for the package",
                "This defaults to the latest version"
        ]),
        CommandOption.value(name: "targets", short: "t", help: ["A comma separated list of the targets to add the new dependency to"]),
        CommandOption.flag(name: "xcode", short: "x", help: ["Regenerate the Xcode project after the install is complete"])
    ]
    
    public var help: [String] = ["Installs a package into the current project"]
    
    public init() {
        #if !os(Linux)
        self.options.append(
            CommandOption.value(name: "playground", short: "p", help: [
                "The name of the playground to install the package to, if you want to install the package to a playground."
            ])
        )
        #endif
    }
    
    public func run(using context: CommandContext) throws -> Future<Void> {
        #if !os(Linux)
        if let playground = context.options["playground"] {
            let installing = context.console.loadingBar(title: "Installing Dependency")
            _ = installing.start(on: context.container)
            
            let name = try context.argument("name")
            return try self.package(with: name, on: context).flatMap { package in
                return try self.playground(playground, install: package.url, at: package.version, context: context)
                }.map {
                    installing.succeed()
            }
        } else {
            return try install(using: context)
        }
        #else
        return try install(using: context)
        #endif
    }
    
    func install(using context: CommandContext)throws -> Future<Void> {
        context.console.info("Reading Package Targets...")
        let targets = try Manifest.current.targets().map { $0.name }
        let approvedTargets =
            context.options["targets"]?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ??
            self.inquireFor(targets: targets, in: context)
        
        let installing = context.console.loadingBar(title: "Installing Dependency")
        
        let oldPinCount: Int
        
        do {
            oldPinCount = try Manifest.current.resolved().object.pins.count
        } catch { oldPinCount = 0 }
        
        let name = try context.argument("name")
        
        context.console.info("Fetching Package Data...")
        return try self.package(with: name, on: context).map(to: Void.self) { package in
            _ = installing.start(on: context.container)
            
            let version = package.version.first == "v" ? String(package.version.dropFirst()) : package.version
            let dependency = Dependency(url: package.url, version: .from(version))
            try dependency.save()
            
            try approvedTargets.forEach { name in
                guard let target = try Manifest.current.target(withName: name) else { return }
                target.dependencies.append(contentsOf: package.products)
                try target.save()
            }
            _ = try Process.execute("swift", "package", "update")
            let newPinCount = try Manifest.current.resolved().object.pins.count
            
            installing.succeed()
            
            if let _ = context.options["xcode"] {
                let xcodeBar = context.console.loadingBar(title: "Generating Xcode Project")
                _ = xcodeBar.start(on: context.container)
                
                _ = try Process.execute("swift", "package", "generate-xcodeproj")
                xcodeBar.succeed()
                _ = try Process.execute("sh", "-c", "open *.xcodeproj")
            }
            
            context.console.output("📦  \(newPinCount - oldPinCount) packages installed", style: .plain, newLine: true)
            
            let config = try Configuration.get()
            try config.commit(with: config.installCommit, on: context, replacements: [name])
        }
    }
    
    /// Asks the user if they want to add a dependency to the targets in the package manifest.
    ///
    /// - Parameter targets: The names of the targets available.
    /// - Returns: The names of the targets that where accepted.
    fileprivate func inquireFor(targets: [String], in context: CommandContext) -> [String] {
        var acceptedTargets: [String] = []
        var index = 0

        if targets.count > 1 {
            targetFetch: while index < targets.count {
                let target = targets[index]
                let response = context.console.ask(ConsoleText(stringLiteral: "Would you like to add the package to the target '\(target)'? (y,n,q,?)"))

                switch response {
                case "y":
                    acceptedTargets.append(target)
                    index += 1
                case "n":
                    index += 1
                case "q":
                    break targetFetch
                default: context.console.output("""
                y: Add the package as a dependency to the target.
                n: Do not add the package as a dependency to the target.
                q: Do not add the package as a dependency to the current target or any of the following targets.
                ?: Output this message.
                """, style: .info, newLine: true)
                }
            }
        } else {
            acceptedTargets.append(targets[0])
        }

        return acceptedTargets
    }
    
    func package(with name: String, on context: CommandContext)throws -> Future<(url: String, version: String, products: [String])> {
        let client = try context.container.make(Client.self)
        let token = try Configuration.get().token()
        
        let fullName: Future<String>
        if name.contains("/") {
            let url = "https://package.vapor.cloud/packages/\(name)"
            fullName = client.get(url).flatMap(to: String.self) { response in
                response.content.get(String.self, at: "full_name")
            }
        } else {
            let search = "https://package.vapor.cloud/packages/search?name=\(name)"
            fullName = client.get(search, headers: ["Authorization": "Bearer \(token)"]).flatMap(to: String.self) { response in
                response.content.get(String.self, at: "repositories", 0, "nameWithOwner")
            }
        }
        
        let version = fullName.flatMap(to: String.self) { fullName in
            let names = fullName.split(separator: "/").map(String.init)
            return try self.version(owner: names[0], repo: names[1], token: token, on: context)
        }.map(to: String.self) { version in
            return version
        }
        
        let products = fullName.flatMap(to: [String].self) { fullName in
            let names = fullName.split(separator: "/").map(String.init)
            return try self.products(owner: names[0], repo: names[1], token: token, on: context)
        }
        
        return map(to: (url: String, version: String, products: [String]).self, fullName, version, products) { name, version, products in
            let url = "https://github.com/\(name).git"
            return (url, version, products)
        }
    }
    
    fileprivate func version(owner: String, repo: String, token: String, on context: CommandContext)throws -> Future<String> {
        let client = try context.container.make(Client.self)
        return client.get("https://package.vapor.cloud/packages/\(owner)/\(repo)/releases", headers: ["Authorization":"Bearer \(token)"]).flatMap(to: [String].self) { response in
            return try response.content.decode([String].self)
        }.map(to: String.self) { releases in
            guard let first = releases.first else {
                throw EtherError(
                    identifier: "noReleases",
                    reason: "No tags where found for the selected package. You might want to open an issue on the package requesting a release."
                )
            }
            
            if first.lowercased().contains("rc") || first.lowercased().contains("beta") || first.lowercased().contains("alpha") {
                let majorVersion = Int(String(first.first ?? "0")) ?? 0
                if majorVersion > 0 && releases.count > 1 {
                    var answer: String = "replace"
                    
                    while true {
                        answer = context.console.ask(
                            ConsoleText(stringLiteral:"The latest version found (\(first)) is a pre-release. Would you like to use an earlier stable release? (y/N)")
                        ).lowercased()
                        if answer == "y" || answer == "n" || answer == "" { break }
                    }
                    
                    if answer == "y" {
                        return releases.filter { Int(String($0.first ?? "0")) ?? 0 != majorVersion }.first ?? first
                    } else {
                        return first
                    }
                } else {
                    return first
                }
            } else {
                return first
            }
        }
    }
    
    fileprivate func products(owner: String, repo: String, token: String, on context: CommandContext)throws -> Future<[String]> {
        let client = try context.container.make(Client.self)
        return client.get("https://package.vapor.cloud/packages/\(owner)/\(repo)/manifest", headers: ["Authorization":"Bearer \(token)"]).flatMap(to: [Product].self) { response in
            return response.content.get([Product].self, at: "products")
        }.map(to: [String].self) { products in
            if let index = products.index(where: { $0.name.lowercased() == repo.lowercased() }) {
                return [products[index].name]
            }
            if products.count < 1 { return [repo] }
            
            var allowed: [String]? = nil
            
            repeat {
                let options = products.enumerated().map { return "\($0.offset). \($0.element)" }
                let question = ["Unable to automatically detect product to add to target(s). Answer with comma seperated list of products to add"] + options
                let seletions = context.console.ask(ConsoleText(stringLiteral: question.joined(separator: "\n")))
                let indexes = seletions.split(separator: "\n").map(String.init).map { $0.trimmingCharacters(in: .whitespaces) }.compactMap(Int.init)
                
                let selected = products.enumerated().filter { indexes.contains($0.offset) }.map { $0.element.name }
                if selected.count > 0 { allowed = selected }
            } while allowed == nil
            
            return allowed!
        }
    }
}

struct Product: Content {
    let name: String
}
