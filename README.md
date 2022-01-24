# dsc_lite

[wmf-5.0]: https://www.microsoft.com/en-us/download/details.aspx?id=50395
[DSCResources]: https://github.com/powershell/DSCResources
[wmf5-blog-post]: https://msdn.microsoft.com/en-us/powershell/wmf/5.1/release-notes
[wmf5-blog-incompatibilites]: https://msdn.microsoft.com/en-us/powershell/wmf/5.1/productincompat

#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with dsc_lite](#setup)
3. [Usage - Configuring options and additional functionality](#usage)
    * [Specifying a DSC Resource version](#specifying-a-dsc-resource-version)
    * [Using PSCredential or MSFT_Credential](#using-pscredential-or-msft_credential)
    * [Using EmbeddedInstance or CimInstance](#using-ciminstance)
    * [Handling Reboots with DSC](#handling-reboots-with-dsc)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
    * [Known Issues](#known-issues)
    * [Running Puppet and DSC without Administrative Privileges](#running-puppet-and-dsc-without-administrative-privileges)
7. [Development - Guide for contributing to the module](#development)
8. [Learn More About DSC](#learn-more-about-dsc)
9. [License](#license)

## Module description

The Puppet `dsc_lite` module allows you to manage target nodes using arbitrary Windows PowerShell DSC (Desired State Configuration) Resources.

### Warning:

***Using dsc_lite requires advanced experience with DSC and PowerShell, unlike our other modules that are far easier to use. It is an alternative approach to Puppet's family of [DSC modules](http://forge.puppet.com/dsc), providing more flexibility for certain niche use cases. There are many drawbacks to this approach and we highly recommend that you use the existing family of [DSC modules](http://forge.puppet.com/dsc) instead.***

The `dsc_lite` module contains a lightweight `dsc` type, which a streamlined and minimal representation of a DSC Resource declaration in Puppet syntax. This type does not contain any DSC resources itself, but can invoke arbitrary DSC Resources that already exist on the managed node. Much like the `exec` type, it simply passes parameters through to the underlying DSC Resource without any validation.

This means that you are responsible for:

1. Distributing the DSC Resources as needed to your managed nodes.
1. Validating all configuration data for `dsc` declarations to prevent runtime errors.
1. Troubleshooting all errors without property status reporting.

The existing family of [DSC modules](http://forge.puppet.com/dsc) will manage all the DSC administration for you, meaning that all you need to do is install the module and start writing code. These modules also do parameter validation, meaning that errors surface during development instead of at runtime. And the VS Code integration will show you usage documentation as you write the code. These modules are automatically imported from the PowerShell Gallery on a daily basis, so they're always up to date.

You should *only* use the `dsc_lite` module if either of these cases apply to you:

* You need to use multiple versions of the same DSC resource
* You need to use a DSC resource that isn't published to the [Puppet Forge](http://forge.puppet.com/dsc).
    * If you find a DSC Resource that hasn't been automatically imported, it's very likely due to the original DSC Resource failing schema validation. The `dsc_lite` module can get you by, but you should report the error upstream so that the original author can correct their code.
    * If you have custom DSC Resources, you can use the [Puppet.dsc module builder](https://github.com/puppetlabs/Puppet.Dsc) to build your own Puppet module from it.

------

### Windows system prerequisites

At least PowerShell 5.0, which is included in [Windows Management Framework 5.0][wmf-5.0].

*Note: PowerShell version as obtained from `$PSVersionTable` must be 5.0.10586.117 or greater.*

## Setup

~~~bash
puppet module install puppetlabs-dsc_lite
~~~

See [known issues](#known-issues) for troubleshooting setup.

## Usage

The generic `dsc` type is a streamlined and minimal representation of a DSC Resource declaration in Puppet syntax. You can use a DSC Resource by supplying the same properties you would set in a DSC Configuration script, inside the `properties` parameter. For most use cases, the `properties` parameter accepts the same structure as the PowerShell syntax, with the substitution of Puppet syntax for arrays, hashes, and other data structures. You can use PowerShell on the command-line to identify the available parameters.

~~~powershell
PS C:\Users\Administrator> Get-DscResource WindowsFeature | Select-Object -ExpandProperty Properties

Name                 PropertyType   IsMandatory Values
----                 ------------   ----------- ------
Name                 [string]              True {}
Credential           [PSCredential]       False {}
DependsOn            [string[]]           False {}
Ensure               [string]             False {Absent, Present}
IncludeAllSubFeature [bool]               False {}
LogPath              [string]             False {}
PsDscRunAsCredential [PSCredential]       False {}
Source               [string]             False {}
~~~

An example of that DSC resource specified in PowerShell:

~~~powershell
WindowsFeature IIS {
  Ensure => 'present'
  Name   => 'Web-Server'
}
~~~

Would look like this in Puppet:

~~~puppet
dsc {'iis':
  resource_name => 'WindowsFeature',
  module        => 'PSDesiredStateConfiguration',
  properties    => {
    ensure => 'present',
    name   => 'Web-Server',
  }
}
~~~

For the simplest cases, the above example is enough. However there are more advanced use cases in DSC that require more custom syntax in the `dsc` Puppet type. Since the `dsc` Puppet type has no prior knowledge of the type for each property in a DSC Resource, it can't format the hash correctly without some hints.

The `properties` parameter recognizes any key with a hash value that contains two keys: `dsc_type` and `dsc_properties`, as a indication of how to format the data supplied. The `dsc_type` contains the CimInstance name to use, and the `dsc_properties` contains a hash or an array of hashes, representing the data for the CimInstances.

A contrived, but simple example follows:

~~~puppet
dsc {'foo':
  resource_name => 'xFoo',
  module        => 'xFooBar',
  properties    => {
    ensure  => 'present',
    fooinfo => {
      'dsc_type'       => 'FooBarBaz',
      'dsc_properties' => {
        "wakka"  => "woot",
        "number" => 8090
      }
    }
  }
}
~~~

### Specifying a DSC Resource version

When there is more than one version installed for a given DSC Resource module, you must specify the version in your declaration. You can specify the version with similar syntax to a DSC configuration script, by using a hash containing the name and version of the DSC Resource module.

~~~puppet
dsc {'iis_server':
  resource_name => 'WindowsFeature',
  module        => {
    name    => 'PSDesiredStateConfiguration',
    version => '1.1'
  },
  properties => {
    ensure => 'present',
    name   => 'Web-Server',
  }
}
~~~

### Distributing DSC Resources

There are several methods to distribute DSC Resources to the target nodes for the `dsc_lite` module to use.

#### PowerShell Gallery

You can choose to install DSC Resources using a mechanism that calls the builtin PowerShell package management system called `PackageManagement`. It uses the `PowerShellGet` module and pulls from the [PowerShell Gallery](https://www.powershellgallery.com). You are responsible for orchestrating this before Puppet is run on the host, or you can do so using `exec` in your Puppet manifest. This gives you control of the process, but requires you to manage the complexity yourself.

The following example shows how to install the `xPSDesiredStateConfiguration` DSC Resource, and can be extended to support different DSC Resource names. This example assumes a package repository has been configured.

~~~puppet
exec { 'xPSDesiredStateConfiguration-Install':
  command   => 'Install-Module -Name xPSDesiredStateConfiguration -Force',
  provider  => 'powershell',
}
~~~

#### Puppet hbuckle/powershellmodule module

The community created module [hbuckle/powershellmodule](https://forge.puppet.com/hbuckle/powershellmodule) handles using `PackageMangement` and `PowerShellGet` to download and install DSC Resources on target nodes. It is another Puppet `package` provider, so it similar to how you install packages with Puppet for any other use case.

Installing a DSC Resource can be as simple as the following declaration:

~~~puppet
package { 'xPSDesiredStateConfiguration':
  ensure   => latest,
  provider => 'windowspowershell',
  source   => 'PSGallery',
}
~~~

The module supports configuring repository sources and other `PackageManagement` options, for example configuring trusted package repositories and private or on-premise package sources. For more information, please see the [forge page](https://forge.puppet.com/hbuckle/powershellmodule).

#### Chocolatey

Puppet already works well with [chocolatey](https://chocolatey.org/). You can create chocolatey packages that wrap the DSC Resources you need.

~~~puppet
package { 'xPSDesiredStateConfiguration':
  ensure   => latest,
  provider => 'chocolatey',
}
~~~

This works well for users that already have a chocolatey source feed setup internally, as all you need to do is to push the DSC Resource chocolatey packages to the internal feed. If you use the community feed, you will have to check that the DSC Resource you use is present there.

### Using PSCredential or MSFT_Credential

Specifying credentials in DSC Resources requires using a PSCredential object. The `dsc` type automatically creates a PSCredential if the `dsc_type` has `MSFT_Credential` as a value.

~~~puppet
dsc {'foouser':
  resource_name => 'User',
  module        => 'PSDesiredStateConfiguration',
  properties    => {
    'username'    => 'jane-doe',
    'description' => 'Jane Doe user',
    'ensure'      => 'present',
    'password'    => {
      'dsc_type'       => 'MSFT_Credential',
      'dsc_properties' => {
        'user'     => 'jane-doe',
        'password' => Sensitive('StartFooo123&^!')
      }
    },
    'passwordneverexpires' => false,
    'disabled'             => true,
  }
}
~~~

Some DSC Resources require a password or passphrase for a setting, but do not need a user name. All credentials in DSC must be a PSCredential, so these passwords still have to be specified in a PSCredential format, even if there is no `user` to specify. How you specify the PSCredential depends on how the DSC Resource implemented the password requirement. Some DSC Resources accept an empty or null string for `user`, others do not. If it does not accept an empty or null string, then specify a dummy value. Do not use `undef` as it will error out.

You can also use the Puppet [Sensitive type](https://puppet.com/docs/puppet/latest/lang_data_sensitive.html) to ensure logs and reports redact the password.

~~~puppet
dsc {'foouser':
  resource_name => 'User',
  module        => 'PSDesiredStateConfiguration',
  properties    => {
    'username'    => 'jane-doe',
    'description' => 'Jane Doe user',
    'ensure'      => 'present',
    'password'    => {
      'dsc_type'       => 'MSFT_Credential',
      'dsc_properties' => {
        'user'     => 'jane-doe',
        'password' => Sensitive('StartFooo123&^!')
      }
    },
    'passwordneverexpires' => false,
    'disabled'             => true,
  }
}
~~~

### Using CimInstance

A DSC Resource may need a more complex type than a simple key value pair, for example, an EmbeddedInstance. An EmbeddedInstance is serialized as CimInstance over the wire. In order to represent a CimInstance in the `dsc` type, use the `dsc_type` key to specify which CimInstance to use. If the CimInstance is an array, append a `[]` to the end of the name.

For example, create a new IIS website using the xWebSite DSC Resource, bound to port 80. Use `dsc_type` to specify a `MSFT_xWebBindingInformation` CimInstance, and append `[]` to indicate that it is an array. Note that you do this even if you are only putting a single value in `dsc_properties`.

~~~puppet
dsc {'NewWebsite':
  resource_name => 'xWebsite',
  module        => 'xWebAdministration',
  properties    => {
    ensure       => 'Present',
    state        => 'Started',
    name         => 'TestSite',
    physicalpath => 'C:\testsite',
    bindinginfo  => {
      'dsc_type'       => 'MSFT_xWebBindingInformation[]',
      'dsc_properties' => {
        "protocol" => "HTTP",
        "port"     => 80
      }
    }
  }
}
~~~

To show using more than one value in `dsc_properties`, create the same site but bound to both port 80 and 443.

~~~puppet
dsc {'NewWebsite':
  resource_name => 'xWebsite',
  module        => 'xWebAdministration',
  properties    => {
    ensure       => 'Present',
    state        => 'Started',
    name         => 'TestSite',
    physicalpath => 'C:\testsite',
    bindinginfo  => {
      'dsc_type'       => 'MSFT_xWebBindingInformation[]',
      'dsc_properties' => [
        {
          "protocol" => "HTTP",
          "port"     => 80
        },
        {
          'protocol'              => 'HTTPS',
          'port'                  => 443,
          'certificatethumbprint' => 'F94B4CC4C445703388E418F82D1BBAA6F3E9E512',
          'certificatestorename'  => 'My',
          'ipaddress'             => '*'
        }
      ]
    }
  }
}
~~~

### Handling reboots with DSC

Add the following `reboot` resource to your manifest. It must have the name `dsc_reboot` for the `dsc` module to find and use it.

~~~puppet
reboot { 'dsc_reboot' :
  message => 'DSC has requested a reboot',
  when    => 'pending',
  onlyif  => 'pending_dsc_reboot',
}
~~~

## Reference

For information on the types, see [REFERENCE.md](https://github.com/puppetlabs/puppetlabs-dsc_lite/blob/master/REFERENCE.md).

## Limitations

* DSC Composite Resources are not supported.
* DSC requires PowerShell `Execution Policy` for the `LocalMachine` scope to be set to a less restrictive setting than `Restricted`. If you see the error below, see [MODULES-2500](https://tickets.puppet.com/browse/MODULES-2500) for more information.

  ~~~
  Error: /Stage[main]/Main/Dsc_xgroup[testgroup]: Could not evaluate: Importing module MSFT_xGroupResource failed with
  error - File C:\Program
  Files\WindowsPowerShell\Modules\PuppetVendoredModules\xPSDesiredStateConfiguration\DscResources\MSFT_xGroupR
  esource\MSFT_xGroupResource.psm1 cannot be loaded because running scripts is disabled on this system. For more
  information, see about_Execution_Policies at http://go.microsoft.com/fwlink/?LinkID=135170.
  ~~~

* You cannot use forward slashes for the MSI `Path` property for the `Package` DSC Resource. The underlying implementation does not accept forward slashes instead of backward slashes in paths, and it throws a misleading error that it could not find a Package with the Name and ProductId provided. See [MODULES-2486](https://tickets.puppet.com/browse/MODULES-2486) for more examples and information on this subject.
* Using this module with the 3.8.x x86 version of Puppet is highly discouraged, though it is supported.  Normally, this module employs a technique to dramatically improve performance by reusing a PowerShell process to execute DSC related commands.  However, due to the Ruby 1.9.3 runtime used with the 3.8.x x86 version of Puppet, this technique must be disabled, resulting in at least a 2x slowdown.

### Known Issues

`--noop` mode, `puppet resource` and property change notifications are currently not implemented. See [MODULES-2270](https://tickets.puppet.com/browse/MODULES-2270) for details.

### Running Puppet and DSC without administrative privileges

While there are options for using Puppet with a non-administrative account, DSC is limited to accounts with administrative privileges. The underlying CIM implementation DSC uses for DSC Resource invocation, and the Invoke-DscResource cmdlet, require administrative credentials.

The Puppet agent on a Windows node can run DSC with a normal default install. If the Puppet agent is configured to use an alternate user account, it must have administrative privileges on the system to run DSC.

## Troubleshooting

When Puppet runs, the dsc_lite module takes the code supplied in your Puppet manifest and converts it into PowerShell code that is sent directly to the DSC engine using `Invoke-DscResource`. You can see both the commands sent and the result of this by running Puppet interactively, for example, `puppet apply --debug`. It outputs the PowerShell code that is sent to DSC to execute and return data from DSC. For example:

```puppet
Notice: Compiled catalog for win2012r2 in environment production in 0.82 seconds
Debug: Creating default schedules
Debug: Loaded state in 0.03 seconds
Debug: Loaded state in 0.05 seconds
Info: Applying configuration version '1475264065'
Debug: Reloading posix reboot provider
Debug: Facter: value for uses_win32console is still nil
Debug: PowerShell Version: 5.0.10586.117
$invokeParams = @{
Name          = 'ExampleDSCResource'
Method        = 'test'
Property      = @{
property1 = 'value1'
property2 = 'value2'
}
ModuleName = 'ExampleDscResourceModule'
}
############### SNIP ################
Debug: Waited 50 milliseconds...
############### SNIP ################
Debug: Waited 500 total milliseconds.
Debug: Dsc Resource returned: {"rebootrequired":false,"indesiredstate":false,"errormessage":""}
Debug: Dsc Resource Exists?: false
Debug: ensure: present
############### SNIP ################
$invokeParams = @{
Name          = 'ExampleDSCResource'
Method        = 'set'
Property      = @{
property1 = 'value1'
property2 = 'value2'
}
ModuleName = 'ExampleDscResourceModule'
}
############### SNIP ################\
Debug: Waited 100 total milliseconds.
Debug: Create Dsc Resource returned: {"rebootrequired":false,"indesiredstate":true,"errormessage":""}
Notice: /Stage[main]/Main/Dsc_exampledscresource[foober]/ensure: invoked
Debug: /Stage[main]/Main/Dsc_exampledscresource[foober]: The container Class[Main] will propagate my refresh event
Debug: Class[Main]: The container Stage[main] will propagate my refresh event
Debug: Finishing transaction 56434520
Debug: Storing state
Debug: Stored state in 0.10 seconds
############### SNIP ################
```

This shows us that there wasn't a problem parsing the manifest and turning it into a command to send to DSC. It also shows that there are two commands/operations for every DSC Resource executed, a SET and a test. DSC operates in two stages, it first tests if a system is in the desired state, and then it sets the state of the system to the desired state. You can see the result of each operation in the debug log.

By using the debug logging of a Puppet run, you can troubleshoot the application of DSC Resources during the development of your Puppet manifests.

## Development

Acceptance tests for this module leverage [puppet_litmus](https://github.com/puppetlabs/puppet_litmus).
To run the acceptance tests follow the instructions [here](https://github.com/puppetlabs/puppet_litmus/wiki/Tutorial:-use-Litmus-to-execute-acceptance-tests-with-a-sample-module-(MoTD)#install-the-necessary-gems-for-the-module).
You can also find a tutorial and walkthrough of using Litmus and the PDK on [YouTube](https://www.youtube.com/watch?v=FYfR7ZEGHoE).

If you run into an issue with this module, or if you would like to request a feature, please [file a ticket](https://tickets.puppetlabs.com/browse/MODULES/).
Every Monday the Puppet IA Content Team has [office hours](https://puppet.com/community/office-hours) in the [Puppet Community Slack](http://slack.puppet.com/), alternating between an EMEA friendly time (1300 UTC) and an Americas friendly time (0900 Pacific, 1700 UTC).

If you have problems getting this module up and running, please [contact Support](http://puppetlabs.com/services/customer-support).

If you submit a change to this module, be sure to regenerate the reference documentation as follows:

```bash
puppet strings generate --format markdown --out REFERENCE.md
```

### Contributors

To see who's already involved, see the [list of contributors.](https://github.com/puppetlabs/puppetlabs-dsc/graphs/contributors)

## Learn More About DSC

You can learn more about PowerShell DSC from the following online resources:

- [Microsoft PowerShell Desired State Configuration Overview](https://msdn.microsoft.com/en-us/PowerShell/dsc/overview) - Starting point for DSC topics
- [Microsoft PowerShell DSC Resources page](https://msdn.microsoft.com/en-us/powershell/dsc/resources) - For more information about built-in DSC Resources
- [Microsoft PowerShell xDSCResources Github Repo](https://github.com/PowerShell/DscResources) -  For more information about xDscResources
- [Windows PowerShell Blog](http://blogs.msdn.com/b/powershell/archive/tags/dsc/) - DSC tagged posts from the Microsoft PowerShell Team
- [Using Puppet and DSC to Report on Environment Change - PuppetConf 10-2017 talk](https://youtu.be/dR8VJjDmo9c) and [slides](https://speakerdeck.com/jpogran/using-puppet-and-dsc-to-report-on-environment-change)
- [Puppet Inc Windows DSC & WSUS Webinar 9-17-2015 webinar](https://puppet.com/webinars/windows-dsc-wsus-webinar-09-17-2015) - How DSC works with Puppet
- [Better Together: Managing Windows with Puppet, PowerShell and DSC - PuppetConf 10-2015 talk](https://www.youtube.com/watch?v=TP0zqe-yQto) and [slides](https://speakerdeck.com/iristyle/better-together-managing-windows-with-puppet-powershell-and-dsc)
- [PowerShell.org](http://powershell.org/wp/tag/dsc/) - Community based DSC tagged posts
- [PowerShell Magazine](http://www.powershellmagazine.com/tag/dsc/) - Community based DSC tagged posts

There are several books available as well. Here are some selected books for reference:

- [Learning PowerShell DSC 2nd Edition](https://www.packtpub.com/networking-and-servers/learning-powershell-dsc-second-edition) - James Pogran is a member of the team here at Puppet Inc working on the DSC/Puppet integration
- [The DSC Book](https://www.penflip.com/powershellorg/the-dsc-book) - Powershell.org community contributed content
- [Pro PowerShell Desired State Configuration](https://www.apress.com/us/book/9781484234822) - Ravikanth Chaganti

## License

* Copyright (c) 2014 Marc Sutter, original author
* Copyright (c) 2015 - Present Puppet Inc
* License: [Apache License, Version 2.0](https://github.com/puppetlabs/puppetlabs-dsc/blob/master/LICENSE)
