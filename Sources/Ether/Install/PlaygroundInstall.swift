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
import Console
import Command
import Xgen

extension Install {
    func playground(_ name: String, install package: String, at tag: String, context: CommandContext)throws -> Future<Void> {
        let workspace: Workspace
        let path = try Process.execute("pwd")
        
        if try Process.execute("ls").contains(name + ".xcworkspace") {
            workspace = Workspace(path: path + "/" + name + ".xcworkspace")
            workspace.addPlayground(at: name + ".xcworkspace/" + name + ".playground")
        } else {
            _ = try Process.execute("mkdir", name + ".xcworkspace")
            workspace = Workspace(path: path + "/" + name + ".xcworkspace")
            
            _ = try Process.execute("mv", name + ".playground", name + ".xcworkspace")
            
            let contents = try Process.execute("cat", path + "/" + name + ".xcworkspace/" + name + ".playground/Contents.swift")
            let playground  = Playground(path: name + ".xcworkspace/" + name + ".playground", platform: .macOS, autoRun: true, code: contents)
            workspace.addPlayground(playground)
        }
        
        
        if try !Process.execute("ls", name + ".xcworkspace").contains("Projects") {
            _ = try Process.execute("mkdir", path + "/" + name + ".xcworkspace/Projects")
            
        }
        guard let packageName = package.split(separator: "/").last?.split(separator: ".").first.map(String.init) else {
            throw EtherError(identifier: "badURL", reason: "Unable to extract repo name from URL '\(package)'")
        }
        
        
        _ = try Process.execute("git", "clone", package, "./" + name + ".xcworkspace/Projects/" + packageName, "--depth=1")
        _ = try Process.execute("bash", "-c", "cd " + name + ".xcworkspace/Projects/" + packageName + "; swift package generate-xcodeproj;")
        
        
        let depenencies = try Process.execute("ls", name + ".xcworkspace/Projects/").split(separator: "\n").map(String.init)
        let xcodeProjs = try Process.execute("bash", "-c", "ls " + name + ".xcworkspace/Projects/* | grep '.xcodeproj'").split(separator: "\n").map(String.init)
        
        for dependency in zip(depenencies, xcodeProjs) {
            let dependencyPath: String = name + ".xcworkspace/Projects/" + dependency.0 + "/" + dependency.1
            workspace.addProject(at: dependencyPath)
        }
        
        
        try workspace.generate()
        _ = try Process.execute("xcodebuild", "-workspace", name + ".xcworkspace", "-scheme", packageName + "-Package")
        _ = try Process.execute("sh", "-c", "open " + name + ".xcworkspace")
        
        return context.container.future()
    }
}
