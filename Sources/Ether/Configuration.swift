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
import Helpers
import JSON

public class Configuration: Command {
    public let id: String = "config"
    public let configPath = "/Library/Application Support/Ether/config.json"
    
    public let signature: [Argument] = [
       Value(name: "key", help: [
            "The configuration JSON key to set"
        ]),
       Value(name: "value", help: [
            "The new value for the key passed in"
        ])
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        let setBar = console.loadingBar(title: "Setting Configuration Key")
        setBar.start()
        
        let fileManager = FileManager.default
        let key = try value("key", from: arguments)
        let val = try value("value", from: arguments)
        
        guard let jsonPath = ConfigurationKey.getKey(from: key)?.jsonPath else {
            throw fail(bar: setBar, with: "Unable to get JSON path for specified key")
        }
        guard let configURL = URL(string: "file:\(fileManager.currentDirectoryPath)\(configPath)") else {
            throw fail(bar: setBar, with: "Unable to create path to config file")
        }
        
        let jsonData = try Data(contentsOf: configURL).makeBytes()
        var json = try JSON(bytes: jsonData)
        try self.set(jsonPath, with: val, in: &json)
        
        try Data(bytes: json.makeBytes()).write(to: configURL)
        
        setBar.finish()
    }
    
    fileprivate func set(_ path: [String], with val: Any?, `in` json: inout JSON)throws {
        var jsons: [(key: String, json: JSON)] = []
        var top: JSON = JSON()
        var sub: JSON = JSON()
        
        if path.count < 1 { return }
        for key in path {
            try jsons.append((key: key, json: json.get(key)))
        }
        if jsons.count == 0 { return }
        else if jsons.count == 1 {
            top = jsons[0].json
            try top.set(path[0], val)
            json = top
            return
        }
        
        for index in Array(0...jsons.count-1).reversed() {
            sub = jsons[index].json
            
            if index == jsons.count-1 {
                // Force-unwrapping always succedes because we tested for the path count earlier.
                try sub.set(path.last!, val)
            } else if index > 0 {
                top = jsons[index].json
                try top.set(jsons[index].key, sub)
            } else {
                json = top
            }
        }
    }
}

fileprivate enum ConfigurationKey {
    case useGit
    case gitInstallMessage
    case gitRemoveMessage
    case gitLatestMessage
    
    var jsonPath: [String] {
        switch self {
        case .useGit: return ["git", "use"]
        case .gitInstallMessage: return ["git", "commit-messages", "install"]
        case .gitRemoveMessage: return ["git", "commit-message", "remove"]
        case .gitLatestMessage: return ["git", "commit-message", "version-latest"]
        }
    }
    
    static func getKey(from string: String) -> ConfigurationKey? {
        switch string.lowercased() {
        case "use-git": return .useGit
        case "install-commit": return .gitInstallMessage
        case "remove-commit": return .gitRemoveMessage
        case "latest-commit": return .gitLatestMessage
        default: return nil
        }
    }
}
