## Unreleased

## 2018-02-02 - Unsupported Release 0.2.0

### Summary

Small release with breaking change to support for DSC Versions

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
