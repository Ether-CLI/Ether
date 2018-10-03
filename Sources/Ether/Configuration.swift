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

import Foundation
import Console
import Command
import Helpers
import Core
import Bits

public class Configuration: Command {
    public var arguments: [CommandArgument] = [
        CommandArgument.argument(name: "key", help: [
            "The configuration JSON key to set",
            "Valid keys are:",
            "- access-token: The GitHub access token to use for interacting the the GraphQL API. You can create one at https://github.com/settings/token",
            "- install-commit: The commit message to use on package install. Use '&0' as package name placeholder",
            "- remove-commit: The commit message to use when a package is removed. Use '&0' as package name placeholder",
            "- new-commit: The commit message to use when a new project is generated. Use '&0' as the project name placeholder",
            "- update-commit: The commit message to use when a project's packages are updated",
            "- version-latest-commit: The commit message to use when you update a project's dependencies to their latest versions",
            "- version-set-commit: The commit message to use when you set a project's dependency to a specific version. Use '&0' as the package name and '&1' as the package's new version placeholders",
            "- signed-commits: If set to a truthy value (true, yes, y, 1), auto-commits will pass in the '-S' flag"
        ]),
        CommandArgument.argument(name: "value", help: ["The new value for the key passed in. If no value is passed in, the key will be removed from the config"])
    ]
    
    public var options: [CommandOption] = [
        CommandOption.flag(name: "print", short: "p", help: ["Outputs config key value. 'value' argument must have a value passed in, but it will not be used."])
    ]
    
    public var help: [String] = ["Configure custom actions to occure when a command is run"]
    
    public init() {}
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let setter = context.console.loadingBar(title: "Setting Configuration Key")
        
        let shouldPrint = context.options["print"] != nil
        let key = try context.argument("key")
        let value = context.arguments["value"]
        let user = try Process.execute("whoami")
        
        if !shouldPrint {
            _ = setter.start(on: context.container)
        }
        
        var configuration = try Configuration.get()
        
        guard let property = Config.properties[key] else {
            throw EtherError(identifier: "noSettingWithName", reason: "No configuration setting found with name '\(key)'")
        }
        
        if shouldPrint {
            context.console.print(configuration[keyPath: property] ?? "nil")
        } else {
            configuration[keyPath: property] = value
        }
        
        if !shouldPrint {
            try JSONEncoder().encode(configuration).write(to: URL(string: "file:/Users/\(user)/Library/Application%20Support/Ether/config.json")!)
            setter.succeed()
        }
        return context.container.future()
    }
    
    public static func get()throws -> Config {
        let user = try Process.execute("whoami")
        let configuration: Data
        
        try FileManager.default.createDirectory(
            at: URL(string: "file:/Users/\(user)/Library/Application%20Support/Ether")!,
            withIntermediateDirectories: true,
            attributes: [:]
        )
        
        if !FileManager.default.fileExists(atPath: "/Users/\(user)/Library/Application Support/Ether/config.json") {
            FileManager.default.createFile(
                atPath: "/Users/\(user)/Library/Application Support/Ether/config.json",
                contents: nil,
                attributes: [:]
            )
        }
        
        let contents = try Data(contentsOf: URL(string: "file:/Users/\(user)/Library/Application%20Support/Ether/config.json")!)
        if contents.count > 0 {
            configuration = contents
        } else {
            configuration = Data([.leftCurlyBracket, .rightCurlyBracket])
        }
        
        return try JSONDecoder().decode(Config.self, from: configuration)
    }
}

public struct Config: Codable, Reflectable {
    public var accessToken: String?
    public var installCommit: String?
    public var removeCommit: String?
    public var newCommit: String?
    public var updateCommit: String?
    public var latestVersionCommit: String?
    public var versionSetCommit: String?
    public var signedCommits: String?
    
    static let properties: [String: WritableKeyPath<Config, String?>] = [
        "access-token": \.accessToken,
        "install-commit": \.installCommit,
        "remove-commit": \.removeCommit,
        "new-commit": \.newCommit,
        "update-commit": \.updateCommit,
        "version-latest-commit": \.latestVersionCommit,
        "version-set-commit": \.versionSetCommit,
        "signed-commits": \.signedCommits
    ]
    
    func token()throws -> String {
        guard let token = self.accessToken else {
            var error = EtherError(
                identifier: "noAccessToken",
                reason: "No access token in configuration"
            )
            error.suggestedFixes = [
                "Create a GitHub token at https://github.com/settings/tokens",
                "Run `ether config access-token <TOKEN>`",
                "The token should have permissions to access public repositorie"
            ]
            throw error
        }
        return token
    }
    
    func signed() -> Bool {
        switch (self.signedCommits ?? "n").lowercased() {
        case "true", "yes", "y", "1": return true
        default: return false
        }
    }
    
    func commit(with message: String?, on context: CommandContext, replacements: [String] = [])throws {
        if var commit = message {
            for (index, value) in replacements.enumerated() {
                commit = commit.replacingOccurrences(of: "&\(index)", with: value)
            }
            
            var commitOptions = ["commit", "-m", commit.description]
            if self.signed() { commitOptions.insert("-S", at: 1) }
            
            _ = try Process.execute("git", "add", "Package.swift", "Package.resolved")
            let commitMessage = try Process.execute("git", commitOptions)
            context.console.print(commitMessage)
        }
    }
}
