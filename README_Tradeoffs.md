# DSC implementations: tradeoffs
`dsc_lite` is a new approach to managing nodes by leveraging Microsoft's [Desired State Configuration](https://docs.microsoft.com/en-us/powershell/dsc/overview).
Puppet has an existing approach in the form of the supported [`dsc` Module](https://github.com/puppetlabs/puppetlabs-dsc).

This document explains the benefits and drawbacks of each approach and why a second approach has been implemented.

## Overview
The approach to managing DSC Resources in `dsc_lite` is to use a generalized Puppet call.
This lets you use any DSC Resource available on the target node but requires you to set all of the configuration data correctly.

Instead of writing a declaration in your Puppet manifest that looks like this:

```puppet
dsc_file {'fruit_file':
  dsc_ensure          => 'present',
  dsc_type            => 'File',
  dsc_destinationpath => 'C:\\Fruit.txt',
  dsc_contents        => 'Apple, Banana, Cherry.',
}
```

You'll write a simplified declaration that looks like this:

```puppet
dsc {'fruit_file':
  dsc_resource_name => 'File',
  dsc_resource_module => 'PSDesiredStateConfiguration',
  dsc_resource_properties => {
    ensure          => 'present',
    content         => 'Apple, Banana, Cherry.',
    destinationpath => 'C:\\Fruit.txt',
  }
}
```

The latter is a generalized resource that allows you to use _any_ DSC Resource which is compatible with [`Invoke-DscResource`](https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/invoke-dscresource?view=powershell-5.1) and is available on the machine that you are configuring, while the former only allows you to use the DSC Resources bundled with the Puppet `dsc` module.

## Why should you use the new `dsc_lite` module?

Use `dsc_lite` if one or more of the following apply to you:

+ You need to use one or more DSC Resources which are _not_ [vendored](#vendoring) into Puppet's `dsc` module
+ You want to use class-based or custom DSC Resources
+ You need to use multiple versions of the same DSC resource
+ You want pluginsync to benefit from a [reduced footprint](#pluginsync-impact) - the file count for the module is reduced from thousands of files to a handful
+ You don't want to build your own custom version of the Puppet `dsc` module to include custom resources
+ You can live without the [validation](#validation) of the existing Puppet `dsc` module
+ You don't mind managing the installation of PowerShell modules containing DSC Resources on your nodes
+ You want to use the latest versions of DSC Resources even if they're not [vendored](#vendoring)

## Why should you keep using the Puppet `dsc` module?

You should consider continuing to use the existing Puppet `dsc` module if one or more of the following apply to you:

+ You want [earlier feedback about the validity of manifest code](#validation)
+ You're only using Microsoft-provided DSC Resources - i.e., not using custom, community-maintained, or class-based DSC Resources
+ You've already got a good [workflow for building an internal release of the Puppet `dsc` module with custom resources](https://github.com/puppetlabs/puppetlabs-dsc/blob/master/README_BUILD.md)
+ You don't want to manage installing DSC Resources on your nodes
+ You need the granularity of reporting in the Puppet Enterprise (PE) console which is based on each resource type being different - allowing you to filter and group on DSC Resources

## Additional considerations

The `dsc_lite` module is currently in an early, unsupported state and undergoing rapid iteration.
It is intended to be a lighter weight alternative to the existing module which primarily trades off flexibility for ease-of-use and safety.

Switching between the two approaches will require some work to update the resource declarations in your manifests.

A primary drawback of using `dsc_lite` is that you're responsible for installing DSC Resources onto all of the nodes you wish to configure with it - the module no longer vendors the DSC Resources for you.

### Vendoring

The existing Puppet `dsc` module vendors numerous DSC Resources into it - that is, the Puppet `dsc` module includes [many PowerShell DSC Resources](https://github.com/puppetlabs/puppetlabs-dsc/tree/master/lib/puppet_x/dsc_resources) inside it.
This means that those DSC Resources are automatically on every machine which has the Puppet `dsc` module without you having to manage them individually.
However, this means that if there are DSC Resources you do _not_ want to sync, or DSC Resources not vendored in the Puppet `dsc` module, you'll need to [rebuild the module to your own specifications](https://github.com/puppetlabs/puppetlabs-dsc/blob/master/README_BUILD.md).

The `dsc_lite` module does not vendor the DSC Resources for you, but neither does it limit you to only using vendored DSC Resources.
Any DSC Resource available on the machine can be used by the `dsc_lite` module.

#### Pluginsync impact
The Puppet `dsc` module vendors many different DSC Resources, and therefore has a large footprint and includes thousands of files.
The pluginsync downloads files from every module in the agent's environment modulepath, regardless of whether the node uses them.
This means that _every_ machine using an environment that includes the Puppet `dsc` module will get thousands of files synced to them.
This can be very slow and has the most noticeable impact amongst short-lived machines.

### Validation
The existing Puppet `dsc` module also gives you valuable development and compile-time validation.
The Puppet `dsc` module is aware of the types required for the DSC Resources, including whether a property should be an `int` or a `string`, whether it should be a well-formed path, and whether or not the property is required for the DSC Resource to properly run.
Because of this awareness, the Puppet `dsc` module is able to give you immediate feedback when parsing your manifest - letting you know right away if you've made a syntactic mistake - and useful, human readable feedback at compile time.

For example, if we specify an integer for a property that requires a path:

```puppet
dsc_file {'fruit_file':
  dsc_ensure          => 'present',
  dsc_type            => 'File',
  dsc_destinationpath => 1,
}
```

In the Puppet `dsc` module we get a well-formed error and the invocation never runs on the machine.

```txt
Notice: Compiled catalog for win-tmihi4gdjn2.localdomain in environment production in 0.30 seconds
Error: Parameter dsc_destinationpath failed on Dsc_file[fruit_file]: Invalid value '1'. Should be a string at C:/code/old.pp:1
```

If we do the same with the new `dsc_lite` module:

```puppet
dsc {'fruit_file':
  dsc_resource_name => 'File',
  dsc_resource_module => 'PSDesiredStateConfiguration',
  dsc_resource_properties => {
    ensure          => 'present',
    destinationpath => 1,
  }
}
```

We get a less clear error message from the code _actually_ running (and erroring) on the machine.

```txt
Notice: Compiled catalog for win-tmihi4gdjn2.localdomain in environment production in 0.46 seconds
Error: /Stage[main]/Main/Dsc[fruit_file]: Could not evaluate: Convert property 'destinationpath' value from type 'SINT64' to type 'STRING' failed
 At line:9, char:2
 Buffer:
irectResourceAccess";
};^

insta

Notice: Applied catalog in 3.33 seconds
```

Because `dsc_lite` is unaware of the types and requirements of any given DSC Resource, the module can't provide validation without actually calling the code.