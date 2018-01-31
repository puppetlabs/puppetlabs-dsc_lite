Test Levels
===========================

This folder contains tests at the acceptance and integration level for the "puppetlabs-dsc" module. The unit
tests are still kept in the "spec" top-level folder of the repository.

## Acceptance Folder

At Puppet Labs we define an "acceptance" test as:

> Validating the system state and/or side effects while completing a stated piece of functionality within a tool.
> This type of test is contained within the boundaries of a tool in order to test a defined functional area within
> that tool.

What this means for this project is that we will install and configure some infrastructure needed for a "puppetlabs-dsc"
environment. (Puppet agent only.)

## Configs Folder

The "configs" folder contains Beaker host configuration files for the various test platforms used by the "acceptance"
and "integration" test suites.

## Library Folder

The "lib" folder contains Beaker helper library that assist in automated testing shared between the "acceptance" and
"integration" test suites.

## Pre-suite Folder

The "pre-suite" folder contains Beaker pre-suite scripts for setting up environments for "acceptance" and
"integration" test suites.

## Running Tests

Included in the sub-folders is the "test_run_scripts" sub-folder for simple Bash scripts that will run suites of
Beaker tests. These scripts utilize environment variables for specifying test infrastructure. For security
reasons we do not provide examples from the Puppet Labs testing environment. Hopefully in the near future we will
be able to provide necessary infrastructure to the community to allow for contributors to run the "acceptance" and
"integration" test suites.

### Running Acceptance Tests

To run acceptance tests use the "acceptance_tests.sh" test run script.

**Example: Run with defaults on Windows 2012 R2**
```
./acceptance_tests.sh
```

**Example: Run with Puppet Agent 1.2.1 on Windows 2008 R2 using Forge**
```
./acceptance_tests.sh windows-2008r2-64a 1.2.1 forge
```

**Example: Run with Puppet Agent 1.2.2 on Windows 2012 R2 with local module code (No Forge)**
```
./acceptance_tests.sh windows-2012r2-64a 1.2.2 local
```

## Documentation

Each sub-folder may contain a "README.md" that describes the content found in the sub-folder if it the content is
not obvious to a contributor.
