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

// {
//  git: {
//    commit: {
//      install: <String>
//      remove: <String>
//      new: <String>
//      update: <String>
//    }
//  }
// }

import Console
import Foundation

public final class Configuration: Command {
    public enum Keys {
        case installCommit(String)
        case removeCommit(String)
        case updateCommit(String)
        case newCommit(String)
        case useGit(Bool)
        
        func parseFrom(_ str: String) -> Keys {
            let key = str.components(separatedBy: ":")[0]
            let value = str.components(separatedBy: ":")[1]
            switch key {
            case "install-commit": return .installCommit(value)
            case "remove-commit": return .removeCommit(value)
            case "update-commit": return .updateCommit(value)
            case "new-commit": return .newCommit(value)
            case "use-git":
                if value == "false" || value == "no" || value == "n" {
                    return .useGit(false)
                } else {
                    return .useGit(true)
                }
            default: fatalError("The key passed in does not exist.")
            }
        }
    }
    
    public let id = "config"
    public let configUrl = "~/Library/Application\\ Support/Ether/config.json"

    public let signature: [Argument] = [
      Value(name: "setting", help: [
          "The configuration key and value for it to be updated to with the format of key:value"
      ])
    ]

    public var help: [String] = [
        "Sets Ether configuration data to customize functionality.",
        "Here is a list of keys, the expected value type, and what it does:",
        "",
        "      Key       | Value  |                        Description                               ",
        "----------------+--------+------------------------------------------------------------------",
        " install-commit | String | The commit message used when a package has been installed        ",
        " remove-commit  | String | The commit message used when a package has been removed          ",
        " update-commit  | String | The commit message when the update command is run                ",
        " new-commit     | String | The commit message used when a project is generated              ",
        " use-git        | Bool   | Whether or not to use Git when a command that would use it is run"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let progressBar = console.loadingBar(title: "Setting value for key")
        progressBar.start()
        
        let fileManager = FileManager.default
        guard let fileData = fileManager.contents(atPath: configUrl) else {
            throw fail(bar: progressBar, with: "The configuration file does not exit. Try running `ether update --self`")
        }
        
        guard let configData = String(data: fileData, encoding: .utf8) else {
            throw fail(bar: progressBar, with: "Unable to read data from configuration file")
        }
        
        
    }
}
