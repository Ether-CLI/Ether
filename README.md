<p align="center">
  <a href="https://github.com/calebkleveter/Ether/blob/master/assets/ether.png?raw=true">
    <img src="https://github.com/calebkleveter/Ether/blob/master/assets/ether.png?raw=true" />
  </a>
</p>

# Ether

[![Mentioned in Awesome Vapor](https://awesome.re/mentioned-badge.svg)](https://github.com/Cellane/awesome-vapor)
![Built with Swift 4.2](https://img.shields.io/badge/swift-4.2-orange.svg)


## What is it?

Ether is a CLI the integrates with SPM (Swift Package Manager), similar to NPM's command-line tool.


## How do I install it?

With Homebrew:

```bash
brew tap Ether-CLI/tap
brew install ether
```

If you don't have, want, or can't use Homebrew, you can run the following script to install Ether:

```bash
curl https://raw.githubusercontent.com/calebkleveter/Ether/master/install.sh | bash
```

## What features does it have?

### Search:

Searches for available packages:

    ether search <name>
    
Example result:

```
Searching [Done]
vapor/vapor: 💧 A server-side Swift web framework.
License: MIT License
Stars: 13906

vapor/toolbox: Simplifies common command line tasks when using Vapor
License: MIT License
Stars: 111

matthijs2704/vapor-apns: Simple APNS Library for Vapor (Swift)
License: MIT License
Stars: 289

vapor-community/postgresql: Robust PostgreSQL interface for Swift
License: MIT License
Stars: 99

...    
```

### Install

Installs a package with its dependencies:

    ether install <name>

Example output:

```
Installing Dependency [Done]
📦  10 packages installed
```

Package.swift:

```
dependencies: [
    .package(url: "https://github.com/vapor/console.git", from: "3.0.0"),
    .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),
    .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0") <=== Added Package
]
```

**Note:**

The install command has a rather interesting method of getting the proper package. Because you can have packages with the same name by different authors, Ether will run a search based on the argument you pass in and get the most stared result. If the name contains a slash (`/`), then the URL will be created directly without a search like this:

    https://github.com/<NAME>.git

Note that this is case insensitive.

### Fix Install

Fixes the install process when an error occurs during `install`, such as a git conflict.

    ether fix-install

Example Output:

```
This may take some time...
Fixing Installation [Done]
```

### Remove

Removes the package and its dependencies from the project:

    ether remove <name>
 
Example output:

```
Removing Dependency [Done]
📦  2 packages removed
```

### Update

Updates the packages. This only needs to be run if packages are manually added.

    ether update

Example output:

    Updating Packages [Done]

You can pass in the `--self` flag to update Ether to the latest version:

    ether update --self

Example output:

    Updating Ether [Done]

### Template Create

Saves the current state of the project as a template that can be used later when creating a new project.

    ether template create <name>

Example output:

    Saving Template [Done]
    
### Template Remove

Saves the current state of the project as a template that can be used later when creating a new project.

    ether template remove <name>

Example output:

    Deleting Template [Done]
    
### Template List

Saves the current state of the project as a template that can be used later when creating a new project.

    ether template list

Example output:

    - Vapor
    - CLI

### New

Creates a project. It can be a Swift package, a Swift executable, or a project from  a previously saved template.

    ether new <name>

Example output:

    Generating Project [Done]

### Version Latest

Sets all packages to their latest versions:

    ether version latest

Example output:

    Updating Package Versions [Done]

### Version All

Outputs the name of each package installed and its version

    ether version all

Example output:

```
Getting Package Data [Done]
Bits: v1.0.0
Console: v2.1.0
Core: v2.0.2
Debugging: v1.0.0
JSON: v2.0.2
Node: v2.0.4
```

## How do I make my package available?

If they are on GitHub, they already are! Ether uses GitHub's GraphQL API to fetch projects with a `Package.swift` file in the project root.

## What license is it under?

Ether is under the [MIT license](https://github.com/Ether-CLI/Ether/blob/master/LICENSE.md).
