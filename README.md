<p align="center">
  <a href="https://github.com/calebkleveter/Ether/blob/master/assets/ether.png?raw=true">
    <img src="https://github.com/calebkleveter/Ether/blob/master/assets/ether.png?raw=true" />
  </a>
</p>

# Ether

[![Mentioned in Awesome Vapor](https://awesome.re/mentioned-badge.svg)](https://github.com/Cellane/awesome-vapor)

### What is it?

Ether is a CLI the integrates with SPM (Swift Package Manager).

### What features does it have?

You can see a whole list of the available commands [here](https://github.com/calebkleveter/Ether/wiki/Features)

### How do I install it?

With Homebrew:

```bash
brew tap Ether-CLI/tap
brew install ether
```

If you don't have, want, or can't use Homebrew, you can run the following script to install Ether:

```bash
curl https://raw.githubusercontent.com/calebkleveter/Ether/master/install.sh | bash
```

### How do I make my package available?

If they are on GitHub, they already are! Ether uses GitHub's GraphQL API to fetch projects with a `Package.swift` file in the project root.

### What license is it under?

Ether is under the MIT license.
