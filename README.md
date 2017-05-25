# Ether

### What is it?

Ether is a CLI the integrates with SPM (Swift Package Manager). It has functionalities such as:

- Search
- Install
- Remove
- Update

With more to be added soon.

### How do I install it?

Currently, the only way is to clone down the repo and run the following commands:

```bash
swift build -c release -Xswiftc -static-stdlib
cd .build/release
cp -f Executable /usr/local/bin/ether
```

A Homebrew formula is in the works.

### How do I make my package available?

Ether uses IBM's [Swift Package Catalog](https://packagecatalog.com/) to search and install packages. Add your packages to it so they can be accessed.

### What license is it under?

Ether is under the MIT license.

