<p align="center">
  <a href="https://github.com/calebkleveter/Ether/blob/master/assets/ether.png?raw=true">
    <img src="https://github.com/calebkleveter/Ether/blob/master/assets/ether.png?raw=true" />
  </a>
</p>

# Ether

**Notice!**

Ether is currently out of comission because the service that was used to fetch package data from (IBM's package catalog) is [no longer hosted](https://packagecatalog.com/). There is work going on for a [replacement](https://github.com/vapor-community/PackageCatalogAPI), but development is moving slowly. If you wold like to pitch in, pop on over to the [Vapor Slack](https://vapor.team/) and ping me @calebkleveter!

### What is it?

Ether is a CLI the integrates with SPM (Swift Package Manager).

### What features does it have?

You can see a whole list of the available commands [here](https://github.com/calebkleveter/Ether/wiki/Features)

### How do I install it?

With Homebrew:

```bash
brew tap calebkleveter/tap
brew install ether
```

If you don't have, want, or can't use Homebrew, you can run the following script to install Ether:

```bash
curl https://raw.githubusercontent.com/calebkleveter/Ether/master/install.sh | bash
```

### How do I make my package available?

Ether uses IBM's [Swift Package Catalog](https://packagecatalog.com/) to search and install packages. Add your packages to it so they can be accessed.

### What license is it under?

Ether is under the MIT license.
