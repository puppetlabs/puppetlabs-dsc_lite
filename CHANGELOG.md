## Unreleased

## 2019-09-05 - Supported Release 2.0.2

### Fixed

- Fixed function that validates paths in $env:lib variable ([MODULES-9800](https://tickets.puppetlabs.com/browse/MODULES-9800))

## 2019-08-22 - Supported Release 2.0.1

### Fixed

- Fixed regression in guarding of library code which caused facter runs to fail on non-Windows systems.

## 2019-08-20 - Supported Release 2.0.0

### Added

- Added a note to the readme specifying the exact PowerShell version required for the module to function ([MODULES-7762](https://tickets.puppetlabs.com/browse/MODULES-7762))

### Changed

- Increase the named pipe timeout to 180 seconds to prevent runs from failing waiting for a pipe to open ([MODULES-9086](https://tickets.puppetlabs.com/browse/MODULES-9086))

### Removed

- Support for Puppet 4x, raising the minimum supported version of Puppet to 5.5.10 ([MODULES-9336](https://tickets.puppetlabs.com/browse/MODULES-9336))

## 2019-04-23 - Supported Release 1.2.1

### Fixed
- Ensure sensitive values are redacted in debug output ([MODULES-8856](https://tickets.puppetlabs.com/browse/MODULES-8856))

## 2019-02-07
### Summary
Release fixes sensitive data types to function when master and agent are different major versions of Puppet.

### Changed
- Updated README.md to prevent daily unwanted reboots when handling reboots with dsc_lite [MODULES-7716](https://tickets.puppetlabs.com/browse/MODULES-7716)
- PDK update to version 1.8.0 [MODULES-8532](https://tickets.puppetlabs.com/browse/MODULES-8532)

### Fixed
- Ensure that using sensitive values in dsc_lite resource declarations functions when the master and agent are different major versions [MODULES-8175](https://tickets.puppetlabs.com/browse/MODULES-8175)

## 2018-11-20
### Changed
Updated metadata for Puppet version 6.x

## 2018-08-30 - Supported Release 1.0.0

### Changed

- Clarify target user for dsc_lite in README ([MODULES-7556](https://tickets.puppetlabs.com/browse/MODULES-7556))
- General README improvements

## 2018-08-02 - Unsupported Release 0.6.0

### Summary

Small release with bug fixes and a reporting improvement.

### Changed

- Ensure the output report for resources prefixes type names with `dsc_lite_#{resource_name}` for improved reporting ([MODULES-7178](https://tickets.puppetlabs.com/browse/MODULES-7178))

### Fixed

- Fix validation for required parameters ([MODULES-7485](https://tickets.puppetlabs.com/browse/MODULES-7485))
- Fix crash on Puppet 4 / WMF < 5 ([MODULES-7554](https://tickets.puppetlabs.com/browse/MODULES-7554))

## 2018-07-10 - Unsupported Release 0.5.0

### Summary

[MODULES-7253](https://tickets.puppetlabs.com/browse/MODULES-7253) introduced a breaking change, where the repetitive use of `dsc_resource_...` was removed.

### Changed

- **BREAKING:**  Renamed all parameters for resource declarations, will require manifest modifications. ([MODULES-7253](https://tickets.puppetlabs.com/browse/MODULES-7253))
- Refactor acceptance tests into beaker rpsec ([MODULES-6572](https://tickets.puppetlabs.com/browse/MODULES-6572), [MODULES-6751](https://tickets.puppetlabs.com/browse/MODULES-6751), [MODULES-6517](https://tickets.puppetlabs.com/browse/MODULES-6517))
- Changed `created` event to `invoked` ([MODULES-7179](https://tickets.puppetlabs.com/browse/MODULES-7179))

### Removed

- Removed unused ensurable values ([MODULES-7197](https://tickets.puppetlabs.com/browse/MODULES-7197))
- Removed redundant acceptance tests ([MODULES-7041](https://tickets.puppetlabs.com/browse/MODULES-7041))

## 2018-06-07 - Unsupported Release 0.4.0

### Summary

Small release with bug fixes.

### Fixed

- Support for `Sensitive` data type ([MODULES-7141](https://tickets.puppetlabs.com/browse/MODULES-7141))
- UTF-8 support in ERB template creation ([MODULES-7143](https://tickets.puppetlabs.com/browse/MODULES-7143))

## 2018-05-23 - Unsupported Release 0.3.0

### Summary

Small release with documentation and minor bug fixes.

### Added

- Added Server 2016 to metadata ([MODULES-4271](https://tickets.puppetlabs.com/browse/MODULES-4271))

### Changed

- Bump the puppetlabs-reboot module dependancy to reflect that the new version is 2.0.0 ([MODULES-6678](https://tickets.puppetlabs.com/browse/MODULES-6678))
- Documented null username PSCredential ([MODULES-6992](https://tickets.puppetlabs.com/browse/MODULES-6992))
- Emit a better message when PowerShell version is unsuitable for provider ([MODULES-6860](https://tickets.puppetlabs.com/browse/MODULES-6860))
- Documented the DSC Resource Distribution process ([MODULES-7105](https://tickets.puppetlabs.com/browse/MODULES-7105))

### Fixed

- Fixed Named Pipes Server on Windows Server 2008r2 ([MODULES-6930](https://tickets.puppetlabs.com/browse/MODULES-6930))


## 2018-02-02 - Unsupported Release 0.2.0

### Summary

Small release with breaking change to support for DSC Versions.

### Changed

- Implement DSC resource version support ([MODULES-5845](https://tickets.puppetlabs.com/browse/MODULES-5845))


## 2018-01-11 - Unsupported Release 0.1.0

### Summary

Initial unsupported release of the dsc_lite module.

### Added

- Implement generic DSC resource ([MODULES-5842](https://tickets.puppetlabs.com/browse/MODULES-5842))
- Update generic dsc resource invoker to support CIM Instances ([MODULES-6323](https://tickets.puppetlabs.com/browse/MODULES-6323))
- Copy Powershell manager from existing DSC module ([MODULES-5844](https://tickets.puppetlabs.com/browse/MODULES-5844))
- Document tradeoffs between generic DSC and current DSC ([MODULES-5847](https://tickets.puppetlabs.com/browse/MODULES-5847))

### Changed

- Rename assets named DSC in the module to the new name of DSC_Lite ([MODULES-5843](https://tickets.puppetlabs.com/browse/MODULES-5843))
- Use dsc_puppetfakeresource in acceptance tests ([MODULES-6132](https://tickets.puppetlabs.com/browse/MODULES-6132))
- Update readme for dsc_lite changes ([MODULES-6378](https://tickets.puppetlabs.com/browse/MODULES-6378))

### Removed

- Remove generated types and vendored code from module ([MODULES-5968](https://tickets.puppetlabs.com/browse/MODULES-5968))
- Remove build tasks and assets from module ([MODULES-6019](https://tickets.puppetlabs.com/browse/MODULES-6019))
