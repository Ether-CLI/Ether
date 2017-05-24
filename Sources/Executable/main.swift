import Console
import Haze
import libc

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
} catch ConsoleError.insufficientArguments {
    terminal.error("Error: ", newLine: false)
    terminal.print("Insufficient arguments.")
} catch ConsoleError.help {
    exit(0)
} catch ConsoleError.cancelled {
    print("Cancelled")
    exit(2)
} catch ConsoleError.noCommand {
    terminal.error("Error: ", newLine: false)
    terminal.print("No command supplied.")
} catch ConsoleError.commandNotFound(let id) {
    terminal.error("Error: ", newLine: false)
    terminal.print("Command \"\(id)\" not found.")
} catch {
    terminal.error("Error: ", newLine: false)
    terminal.print("\(error)")
    exit(1)
}
