import Console
import Haze

var arguments = CommandLine.arguments

let terminal = Terminal(arguments: arguments)

var iterator = arguments.makeIterator()

guard let executable = iterator.next() else {
    throw ConsoleError.noExecutable
}

do {
    try terminal.run(executable: executable, commands: [
        Search(console: terminal)
    ], arguments: Array(iterator),
    help: [
        "Need help? Open an issue on GitHub."
    ])
}
