<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v4.0.1](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/v4.0.1) - 2024-06-06

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/v4.0.0...v4.0.1)

### Fixed

- (bug) - Update readme for release on forge [#211](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/211) ([jordanbreen28](https://github.com/jordanbreen28))

## [v4.0.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/v4.0.0) - 2024-05-29

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/v3.2.0...v4.0.0)

### Changed

- (CAT-1861) Puppet 8 upgrade / Drop Puppet 6 support [#209](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/209) ([LukasAud](https://github.com/LukasAud))

### Added

- pdksync - (FM-8922) - Add Support for Windows 2022 [#196](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/196) ([david22swan](https://github.com/david22swan))

### Fixed

- Fix ERB.new depracation notices [#204](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/204) ([Fabian1976](https://github.com/Fabian1976))

## [v3.2.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/v3.2.0) - 2022-01-27

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/v3.1.0...v3.2.0)

### Added

- (maint) Add messaging about the differences between this and the dsc modules [#188](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/188) ([binford2k](https://github.com/binford2k))

## [v3.1.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/v3.1.0) - 2021-03-31

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/v3.0.1...v3.1.0)

### Added

- (MODULES-10985) - Raise Reboot upper bound to 5 [#175](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/175) ([david22swan](https://github.com/david22swan))
- pdksync - (feat) - Add support for Puppet 7 [#171](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/171) ([daianamezdrea](https://github.com/daianamezdrea))

### Fixed

- (MODULES-10471) Allow namevar to have special chars [#148](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/148) ([jarretlavallee](https://github.com/jarretlavallee))

## [v3.0.1](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/v3.0.1) - 2020-01-16

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/v3.0.0...v3.0.1)

### Fixed

- (MAINT) Safeguard loading ruby-pwsh [#143](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/143) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [v3.0.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/v3.0.0) - 2019-12-13

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/v2.0.2...v3.0.0)

### Changed

- (FM 8425) - Replace Library Code [#134](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/134) ([david22swan](https://github.com/david22swan))

## [v2.0.2](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/v2.0.2) - 2019-09-05

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/v2.0.1...v2.0.2)

### Fixed

- (MODULES-9800) Fix Lib Environment Variable Check [#126](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/126) ([RandomNoun7](https://github.com/RandomNoun7))

## [v2.0.1](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/v2.0.1) - 2019-08-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/v2.0.0...v2.0.1)

### Fixed

- (MAINT) Fix powershell_version OS guard [#122](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/122) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [v2.0.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/v2.0.0) - 2019-08-20

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/1.2.1...v2.0.0)

### Added

- (MODULES-9343) Add Puppet Strings docs [#116](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/116) ([eimlav](https://github.com/eimlav))
- (MODULES-9086) Increase pipe timeout to 180 [#108](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/108) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (MODULES-8171) Run fails if paths in $env:lib don't exist [#109](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/109) ([carabasdaniel](https://github.com/carabasdaniel))
- (MODULES-8602) Resolved declaration conflict between DSC/DSC_Lite [#85](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/85) ([AnthonieSmitASR](https://github.com/AnthonieSmitASR))

## [1.2.1](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/1.2.1) - 2019-04-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/1.2.0...1.2.1)

### Added

- (MODULES-8856) Redact debug [#104](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/104) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (WIN-280) add skip() unless pattern to tests [#102](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/102) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))

## [1.2.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/1.2.0) - 2019-02-05

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/1.1.0...1.2.0)

### Added

- (FM-7693) Add Windows Server 2019 [#98](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/98) ([glennsarti](https://github.com/glennsarti))
- (MODULES-8175) Munge Properties Hash for Sensitive [#92](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/92) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MODULES-8175) Add safety to new-pscredential helper [#91](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/91) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (MODULES-7716) Fix Readme Reboot Snippet [#95](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/95) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-8397) PDK Sync module to fix Travis [#94](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/94) ([RandomNoun7](https://github.com/RandomNoun7))
- Revert "(MODULES-8175) Add safety to new-pscredential helper" [#93](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/93) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [1.1.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/1.1.0) - 2018-11-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/1.0.0...1.1.0)

### Added

- (MODULES-7831) Add Puppet 6 version to metadata. [#88](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/88) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))

## [1.0.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/1.0.0) - 2018-08-27

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/0.6.0...1.0.0)

## [0.6.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/0.6.0) - 2018-08-02

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/0.5.0...0.6.0)

### Added

- (MODULES-7178) Report types dynamically [#69](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/69) ([Iristyle](https://github.com/Iristyle))

### Fixed

- (MODULES-7554) Fix crash on Puppet 4 / WMF < 5 [#72](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/72) ([Iristyle](https://github.com/Iristyle))
- (MODULES-7485) Fix validation for required parameters [#71](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/71) ([jpogran](https://github.com/jpogran))

## [0.5.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/0.5.0) - 2018-07-10

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/0.4.0...0.5.0)

### Changed

- (MODULES-7197) Remove unused ensurable values [#55](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/55) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Added

- (MODULES-6517) add --detailed-exitcodes  [#61](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/61) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- (MODULES-7179) Change created to invoked [#59](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/59) ([RandomNoun7](https://github.com/RandomNoun7))

### Fixed

- (MODULES-7253) Replace verbose parameter names [#58](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/58) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [0.4.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/0.4.0) - 2018-06-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/0.3.0...0.4.0)

### Added

- (MODULES-7143) add UTF-8 encoding to ERB templates. [#51](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/51) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- (MODULES-7141) Support Sensitive data type [#49](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/49) ([jpogran](https://github.com/jpogran))

## [0.3.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/0.3.0) - 2018-05-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/0.2.0...0.3.0)

### Added

- (MODULES-4271) Add Server 2016 to metadata [#43](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/43) ([glennsarti](https://github.com/glennsarti))
- (MODULES-6860) Add `dsc_lite` feature for confines [#41](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/41) ([Iristyle](https://github.com/Iristyle))

### Fixed

- Fix rocket alignment. [#46](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/46) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-6930) Fix Pipes Server On windows2008r2 [#42](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/42) ([RandomNoun7](https://github.com/RandomNoun7))

## [0.2.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/0.2.0) - 2018-02-02

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/0.1.0...0.2.0)

### Added

- (MODULES-6548) Re-add empty file to "integration" [#32](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/32) ([Iristyle](https://github.com/Iristyle))
- (MODULES-5845) Add DSC Resource ModuleSpecification support [#29](https://github.com/puppetlabs/puppetlabs-dsc_lite/pull/29) ([jpogran](https://github.com/jpogran))

## [0.1.0](https://github.com/puppetlabs/puppetlabs-dsc_lite/tree/0.1.0) - 2018-01-10

[Full Changelog](https://github.com/puppetlabs/puppetlabs-dsc_lite/compare/ce53659dd4a376c0347c429040772ee7cf0f00dc...0.1.0)
