# Ether

### What is it?

Ether is a CLI the integrates with SPM (Swift Package Manager). It has functionalities such as:

#### Search:

Searches for available packages:

    ether search <name>
    
Example result:

```
Searching [Done]
Total results: 197
Not all results are shown.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

vapor/vapor: A server-side Swift web framework.

vapor/fluent: Swift models, relationships, and querying for NoSQL and SQL databases.

vapor/sockets: Pure-Swift Sockets: TCP, UDP; Client, Server; Linux, macOS.

vapor/redis: Pure Swift Redis client.

matthijs2704/vapor-apns: Simple APNS Library for Vapor (Swift)

vapor-community/example: Starting point for using the Vapor framework.

vapor/leaf: An extensible templating language built for Vapor. 🍃

vapor/engine: HTTP, WebSockets, Streams, SMTP, etc. Core transport layer used in https://github.com/vapor/vapor

vapor/jwt: JSON Web Tokens in Swift by @siemensikkema.

vapor/toolbox: Simplifies common command line tasks when using Vapor

vapor/console: Swift wrapper for Console I/O

vapor/mysql: Robust MySQL interface for Swift

vapor-community/slack-bot: An example Slack Bot application built with Vapor in Swift.

vapor-community/postgresql: Robust PostgreSQL interface for Swift

vapor-community/forms: Brings simple, dynamic and re-usable web form handling to Vapor.

SwiftyBeaver/SwiftyBeaver-Vapor: SwiftyBeaver Logging Provider for Vapor, the server-side Swift web framework

vapor-community/postgresql-provider: PostgreSQL Provider for the Vapor web framework.

vapor-community/todo-example: An example implementation for http://todobackend.com

vapor-community/chat-example: Realtime chat example built with Vapor.

vapor/crypto: Cryptography modules (formerly CryptoKitten)
    
```

#### Install

Installs a package with its dependencies:

    ether install <name>

Example output:

```
Installing Dependancy [Done]
📦  10 packages installed
```

Package.swift:

```
dependencies: [
    .Package(url: "https://github.com/vapor/console.git", majorVersion: 2),
    .Package(url: "https://github.com/vapor/json.git", majorVersion: 2),
    .Package(url: "https://github.com/vapor/core.git", majorVersion: 2),
    .Package(url: "https://github.com/vapor/vapor.git", Version(2,0,2)) <=== Added Package
]
```

#### Remove

Removes the package and its dependencies from the project:

    ether remove <name>
 
Example output:
    
```
Removing Dependency [Done]
📦  2 packages removed
```

#### Update

Updates the packages. This only needs to be run if packages are manually added.

    ether update

Example output:

    Updating Packages [Done]

With more to be added soon.

### How do I install it?

Currently, the only way is to run the following script:

```bash
curl https://gist.githubusercontent.com/calebkleveter/2e5490c76df227c510035515a49f9f01/raw/49421e072653314160bfe1c506b553805d150cb6/EatherInstall.sh | bash
```
Here is the [Gist that is used](https://gist.github.com/calebkleveter/2e5490c76df227c510035515a49f9f01).

A Homebrew formula is in the works (if you want to help with it, that's fantastic!).

### How do I make my package available?

Ether uses IBM's [Swift Package Catalog](https://packagecatalog.com/) to search and install packages. Add your packages to it so they can be accessed.

### What license is it under?

Ether is under the MIT license.

