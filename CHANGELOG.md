## [1.9.0] 2017-11-15

### Added
- Short flag options for some command's flags.
- Pre-fetching when updating packages.
- Xcode regeneration options.

## [1.8.0] - 2017-11-4

### Added
- `ether fix-install` to replace automatic cache clearing, which can make the install process take an extended amount of time.

## [1.7.0] - 2017-09-18

### Added
- Ether now supports the SPM 4 manifest API!

## [1.6.2] - 2017-09-18

### Fixed
- The position of the dependencies array when a targets array exists.

## [1.6.1] - 2017-09-15

### Fixed
- Fixed bug that caused the install to fail if the dependencies array is non-existent or empty.

## [1.6.0] - 2017-08-2

### Added
- `ether version all` for viewing installed package versions.

## [1.5.2] - 2017-07-30

### Fixed
- `ether --version` flag; again.

## [1.5.1] - 2017-07-30

### Fixed
- `ether --version` flag.

## [1.5.0] - 2017-07-30

### Added
- `ether --version` and `ether -v` for viewing the version of Ether you are using.

## [1.4.2] - 2017-06-2

### Fixed
- Packages are updated after their version is updated.

## [1.4.1] - 2017-06-2

### Changed
- Network requests now use synchronous `get(url parameter)`
- `version latest` only rewrites `Package.swift` once.


## [1.4.0] - 2017-06-2

### Added
- `ether version latest` for updating all packages to their latest version.

## [1.3.0] - 2017-05-31

### Added
- `ether new` for creating new projects.

## [1.2.1] - 2017-05-31

### Fixed
- Attribution for `shell()`
- Fail error typo for the template command.

## [1.2.0] - 2017-05-30

### Added
- Saving and removing project templates

## [1.1.0] - 2017-05-25

### Added
- Updating Ether

### Fixed
- `ether help`

## [1.0.1] - 2017-05-25

### Fixed
- `ether help`

## [1.0.0] - 2017-05-25

### Changed
- Package name {Haze => Ether}

## [0.4.0] - 2017-05-24

### Added
- Package removal

## [0.3.0] - 2017-05-24

### Added
- Package Updating

## [0.2.0] - 2017-05-24

### Added
- Package installation

## [0.1.0] - 2017-05-24

### Added
- Package Searching