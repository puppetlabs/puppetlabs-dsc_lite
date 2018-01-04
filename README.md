# dsc

[wmf-5.0]: https://www.microsoft.com/en-us/download/details.aspx?id=50395
[DSCResources]: https://github.com/powershell/DSCResources
[wmf5-blog-post]: https://msdn.microsoft.com/en-us/powershell/wmf/5.1/release-notes
[wmf5-blog-incompatibilites]: https://msdn.microsoft.com/en-us/powershell/wmf/5.1/productincompat

#### Table of Contents

1. [Description - What is the dsc module and what does it do](#module-description)
2. [Prerequisites](#windows-system-prerequisites)
3. [Setup](#setup)
4. [Usage](#usage)
  * [Using PSCredential or MSFT_Credential](#using-dsc-resources-with-puppet)
  * [Using EmbeddedInstance or CimInstance](#using-dsc-resources-with-puppet)
  * [Handling Reboots with DSC](#handling-reboots-with-dsc)
5. [Reference](#reference)
  * [Types and Providers](#types-and-providers)
6. [Limitations](#limitations)
  * [Known Issues](#known-issues)
  * [Running Puppet and DSC without Administrative Privileges](#running-puppet-and-dsc-without-administrative-privileges)
7. [Development - Guide for contributing to the module](#development)
8. [Places to Learn More About DSC](#places-to-learn-more-about-dsc)
9. [License](#license)

## Description

The Puppet dsc module manages Windows PowerShell DSC (Desired State Configuration) resources.

This module generates Puppet types based on DSC Resources MOF (Managed Object Format) schema files.

In this version, the following DSC Resources are already built and ready for use:

- All base DSC resources found in PowerShell 5 ([WMF 5.0][wmf-5.0]).
- All DSC resources found in the [Microsoft PowerShell DSC Resource Kit][DSCResources]

## Windows System Prerequisites

 - PowerShell 5, which is included in [Windows Management Framework 5.0][wmf-5.0].
 - [Windows 2003 is not supported](#known-issues).

## Setup

~~~bash
puppet module install puppetlabs-dsc
~~~

See [known issues](#known-issues) for troubleshooting setup.

## Usage

### Using PSCredential or MSFT_Credential

The generic `dsc` type is a streamlined and minimal representation of a DSC Resource declaration in Puppet syntax. You can use a DSC Resource by supplying the same properties you would set in a DSC Configuration script inside the `dsc_resource_properties` parameter. For most use cases the `dsc_resource_properties` parameter accepts the same structure as the PowerShell syntax, with the substituion of Puppet syntax for arrays, hashes and other data structures.

So a DSC resource specified in PowerShell...

~~~powershell
WindowsFeature IIS {
  Ensure = 'present'
  Name   = 'Web-Server'
}
~~~

...would look like this in Puppet:

~~~puppet
dsc {'iis':
  dsc_resource_name        => 'WindowsFeature',
  dsc_resource_module_name => 'PSDesiredStateConfiguration',
  dsc_resource_properties  => {
    ensure => 'present',
    name   => 'Web-Server',
  }
}
~~~

For the simplest cases, the above example is enough. However there are more advanced use cases in DSC that require more custom syntax in the `dsc` Puppet type. Since the `dsc` Puppet type has no prior knowledge of the type for each property in a DSC Resource, it can't format the hash correctly without some hints.

The `dsc_resource_properties` parameter will recognize any key with a hash value that contains two keys: `dsc_type` and `dsc_properties`, as a indication of how to format the data supplied. The `dsc_type` contains the CimInstance name to use, and the `dsc_properties` contains a hash or an array of hashes representing the data for the CimInstances.

A contrived, but simple example follows:

~~~puppet
dsc{'foo':
  dsc_resource_name        => 'xFoo',
  dsc_resource_module_name => 'xFooBar',
  dsc_resource_properties  => {
    ensure  => 'present',
    fooinfo => {
      'dsc_type'       => 'FooBarBaz',
      'dsc_properties' => {
        "wakka" => "woot",
        "number"     => 8090
      }
    }
  }
}
~~~

### Using PSCredential or MSFT_Credential

Specifying credentials in DSC Resources requires using a PSCredential object. The `dsc` type will automatically create a PSCredential if the `dsc_type` has `MSFT_Credential` as a value.

~~~puppet
dsc{'foouser':
  dsc_resource_name        => 'User',
  dsc_resource_module_name => 'PSDesiredStateConfiguration',
  dsc_resource_properties  => {
    'username'    => 'jane-doe',
    'description' => 'Jane Doe user',
    'ensure'      => 'present',
    'password'    => {
      'dsc_type' => 'MSFT_Credential',
      'dsc_properties' => {
        'user'     => 'jane-doe',
        'password' => 'StartFooo123&^!'
      }
    },
    'passwordneverexpires' => false,
    'disabled'             => true,
  }
}
~~~

### Using CimInstance

A DSC Resource may need a more complex type that a simple key value pair, so an EmbeddedInstance is used. An EmbeddedInstance is serialized as CimInstance over the wire. In order to represent a CimInstance in the `dsc` type, we will use the `dsc_type` key to specify which CimInstance to use. If the CimInstance is an array, we append a `[]` to the end of the name.

For example, we'll create a new IIS website using the xWebSite DSC Resource, bound to port 80. We use `dsc_type` to specify a `MSFT_xWebBindingInformation` CimInstance, and append `[]` to indicate that it is an array. Note that we do this even if we are only putting a single value in `dsc_properties`.

~~~puppet
dsc{'NewWebsite':
  dsc_resource_name        => 'xWebsite',
  dsc_resource_module_name => 'xWebAdministration',
  dsc_resource_properties  => {
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

To show using more than one value in `dsc_properties`, let's create the same site but now bound to both port 80 and 443.

~~~puppet
dsc{'NewWebsite':
  dsc_resource_name        => 'xWebsite',
  dsc_resource_module_name => 'xWebAdministration',
  dsc_resource_properties  => {
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
          'protocol'             => 'HTTPS',
          'port'                 => 443,
          'certificatethumbprint' => 'F94B4CC4C445703388E418F82D1BBAA6F3E9E512',
          'certificatestorename'  => 'My',
          'ipaddress'            => '*'
        }
      ]
    }
  }
}
~~~


### Handling Reboots with DSC

Add the following `reboot` resource to your manifest. It must have the name `dsc_reboot` for the `dsc` module to find and use it.

~~~puppet
reboot { 'dsc_reboot' :
  message => 'DSC has requested a reboot',
  when => 'pending'
}
~~~

## Reference

### Types and Providers

* [dsc](#dsc)

### dsc

The `dsc` type allows specifying any DSC Resource declaration as a minimal Puppet declaration.

#### Properties/Parameters

#### name

The name of the declaration. This has no affect on the DSC Resource declaration and is not used by the DSC Resource.

#### dsc_resource_name

The name of the DSC Resource to use. For example, the xRemoteFile DSC Resource.

#### dsc_resource_module_name

The name of the DSC Resource module to use. For example, the xPSDesiredStateConfiguration DSC Resource module contains the xRemoteFile DSC Resource.

#### dsc_resource_properties

The hash of properties to pass to the DSC Resource.

To express EmbeddedInstances, the `dsc_resource_properties` parameter will recognize any key with a hash value that contains two keys: `dsc_type` and `dsc_properties`, as a indication of how to format the data supplied. The `dsc_type` contains the CimInstance name to use, and the `dsc_properties` contains a hash or an array of hashes representing the data for the CimInstances. If the CimInstance is an array, we append a `[]` to the end of the name.

## Limitations

- DSC Composite Resources are not supported.

- DSC requires PowerShell `Execution Policy` for the `LocalMachine` scope to be set to a less restrictive setting than `Restricted`. If you see the error below, see [MODULES-2500](https://tickets.puppet.com/browse/MODULES-2500) for more information.

  ~~~
  Error: /Stage[main]/Main/Dsc_xgroup[testgroup]: Could not evaluate: Importing module MSFT_xGroupResource failed with
  error - File C:\Program
  Files\WindowsPowerShell\Modules\PuppetVendoredModules\xPSDesiredStateConfiguration\DscResources\MSFT_xGroupR
  esource\MSFT_xGroupResource.psm1 cannot be loaded because running scripts is disabled on this system. For more
  information, see about_Execution_Policies at http://go.microsoft.com/fwlink/?LinkID=135170.
  ~~~

- You cannot use forward slashes for the MSI `Path` property for the `Package` DSC Resource. The underlying implementation does not accept forward slashes instead of backward slashes in paths, and it throws a misleading error that it could not find a Package with the Name and ProductId provided. [MODULES-2486](https://tickets.puppet.com/browse/MODULES-2486) has more examples and information on this subject.
- `dsc_ensure` overrides and ignores the value in `ensure` if both are present in a Puppet DSC resource. See [Using DSC Resources with Puppet](#using-dsc-resources-with-puppet).
- Use of this module with the 3.8.x x86 version of Puppet is highly discouraged, though supported.  Normally, this module employs a technique to dramatically improve performance by reusing a PowerShell process to execute DSC related commands.  However, due to the Ruby 1.9.3 runtime used with the 3.8.x x86 version of Puppet, this technique must be disabled, resulting in at least a 2x slowdown.

### Known Issues

- The `dsc_log` resource might not appear to work. The ["Log" resource](https://technet.microsoft.com/en-us/library/Dn282117.aspx) writes events to the 'Microsoft-Windows-Desired State Configuration/Analytic' event log, which is [disabled by default](https://technet.microsoft.com/en-us/library/Cc749492.aspx).

- You might have issues if you attempt to use `dsc_ensure => absent` with `dsc_service` with services that are not running.

  When setting resources to absent, you might normally specify a minimal statement such as:

  ~~~puppet
  dsc_service{'disable_foo':
    dsc_ensure => absent,
    dsc_name => 'foo'
  }
  ~~~

  However, due to the way the Service DSC Resource sets its defaults, if the service is not currently running, the above statement erroneously reports that the service is already absent. To work around this, specify that `State => 'Stopped'` as well as `Ensure => absent'`. The following example works:

  ~~~puppet
  dsc_service{'disable_foo':
    dsc_ensure => absent,
    dsc_name   => 'foo',
    dsc_state  => 'stopped'
  }
  ~~~

  [MODULES-2512](https://tickets.puppet.com/browse/MODULES-2512) has more details.

- You might have issues attempting to use `dsc_ensure => absent` with `dsc_xservice` with services that are already not present. To work around this problem, always specify the path to the executable for the service when specifying `absent`. [MODULES-2512](https://tickets.puppet.com/browse/MODULES-2512) has more details. The following example works:

  ~~~puppet
  dsc_xservice{'disable_foo':
    dsc_ensure => absent,
    dsc_name   => 'foo',
    dsc_path   => 'c:\\Program Files\\Foo\\bin\\foo.exe'
  }
  ~~~

- Use `ensure` instead of `dsc_ensure` - `ensure => absent` will report success while doing nothing - see [MODULES-2966](https://tickets.puppet.com/browse/MODULES-2966) for details. Also see [Using DSC Resources with Puppet](#using-dsc-resources-with-puppet).

- When installing the module on Windows you might run into an issue regarding long file names (LFN) due to the long paths of the generated schema files. If you install your module on a Linux master, and then use plugin sync you will likely not see this issue. If you are attempting to install the module on a Windows machine using `puppet module install puppetlabs-dsc` you may run into an error that looks similar to the following:

  ~~~puppet
  Error: No such file or directory @ rb_sysopen - C:/ProgramData/PuppetLabs/puppet/cache/puppet-module/cache/tmp-unpacker20150713-...mof
  Error: Try 'puppet help module install' for usage
  ~~~

  For Puppet 4.2.2+ (and 3.8.2) we've decreased the possibility of the issue occurring based on the fixes in [PUP-4854](https://tickets.puppet.com/browse/PUP-4854). A complete fix is plannd in a future version of Puppet that incorporates [PUP-4866](https://tickets.puppet.com/browse/PUP-4866).

  If you are affected by this issue:
  - Use the `--module_working_dir` parameter to set a different temporary directory which has a smaller length, for example;
    `puppet module install puppetlabs-dsc --module_working_dir C:\Windows\Temp`
  - Download the `.tar.gz` from the [Forge](https://forge.puppet.com/puppetlabs/dsc) and use `puppet module install` using the downloaded file, rather than directly installing from the Forge.

- Windows Server 2003 is not supported. **If this module is present on the master, it breaks Windows 2003 agents.**

  When installed on a Puppet master to the default `production` environment, this module causes pluginsync to **fail** on Windows 2003 agents because of an issue with [LFN (long file names)](https://tickets.puppet.com/browse/PUP-4866). To work around this issue, host your Windows 2003 nodes on a [Puppet environment](https://docs.puppet.com/puppet/latest/reference/environments.html) that is separate from `production` and that does **not** have the DSC module installed.

- `--noop` mode, `puppet resource` and property change notifications are currently not implemented - see [MODULES-2270](https://tickets.puppet.com/browse/MODULES-2270) for details.

- [Known WMF 5.0 Product Incompatibilites][wmf5-blog-incompatibilites]

  Systems that are running the following server applications should not run Windows Management Framework 5.0 at this time:
   - Microsoft Exchange Server 2013
   - Microsoft Exchange Server 2010 SP3
   - Microsoft SharePoint Server 2013
   - Microsoft SharePoint Server 2010
   - System Center 2012 Virtual Machine Manager

- The `Registry` DSC Resource continually changes state, even if the system state matches the desired state, when using a HEX value. See issue [#237](https://github.com/puppetlabs/puppetlabs-dsc/issues/237) for more information.

- The Puppet DSC module hangs on systems with WMF 5.1 installed. This is being addressed in [MODULES-3690](https://tickets.puppetlabs.com/browse/MODULES-3690).

- If you create files with the `dsc_file` resource, the resulting file on disk will be UTF-8 with BOM. This can be a problem if you use tools that are not UTF-8 BOM aware. This is by design for Microsoft PowerShell DSC. More information can be found in [MODULES-3178](https://tickets.puppetlabs.com/browse/MODULES-3178).

### Running Puppet and DSC without Administrative Privileges

While there are avenues for using Puppet with a non-administrative account, DSC is limited to only accounts with administrative privileges. The underlying CIM implementation DSC uses for DSC Resource invocation requires administrative credentials to function.

- Using the Invoke-DscResource cmdlet requires administrative credentials

The Puppet agent on a Windows node can run DSC with a normal default install. If the Puppet agent was configured to use an alternate user account, that account must have administrative privileges on the system in order to run DSC.

## Troubleshooting

When Puppet runs, the dsc module takes the code supplied in your puppet manifest and converts that into PowerShell code that is sent to the DSC engine directly using `Invoke-DscResource`. You can see both the commands sent and the result of this by running puppet interactively, e.g. `puppet apply --debug`. It will output the PowerShell code that is sent to DSC to execute and the return data from DSC. For example:

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
  ModuleName = @{
    ModuleName      = "C:/puppetlabs/modules/dsc/lib/puppet_x/dsc_resources/ExampleDSCResource/ExampleDSCResource.psd1"
    RequiredVersion = "1.0"
  }
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
  ModuleName = @{
    ModuleName      = "C:/puppetlabs/modules/dsc/lib/puppet_x/dsc_resources/ExampleDSCResource/ExampleDSCResource.psd1"
    RequiredVersion = "1.0"
  }
}
############### SNIP ################\
Debug: Waited 100 total milliseconds.
Debug: Create Dsc Resource returned: {"rebootrequired":false,"indesiredstate":true,"errormessage":""}
Notice: /Stage[main]/Main/Dsc_exampledscresource[foober]/ensure: created
Debug: /Stage[main]/Main/Dsc_exampledscresource[foober]: The container Class[Main] will propagate my refresh event
Debug: Class[Main]: The container Stage[main] will propagate my refresh event
Debug: Finishing transaction 56434520
Debug: Storing state
Debug: Stored state in 0.10 seconds
############### SNIP ################
```

This shows us that there wasn't any problem parsing your manifest and turning it into a command to send to DSC. It also shows that there are two commands/operations for every DSC Resource executed, a SET and a test. DSC operates in two stages, it first tests if a system is in the desired state, then it sets the state of the system to the desired state. You can see the result of each operation in the debug log.

By using the debug logging of a puppet run, you can troubleshoot the application of DSC Resources during the development of your puppet manifests.

## Development

Puppet Inc modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can’t access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

For more information, see our [module contribution guide.](https://docs.puppet.com/forge/contributing.html)

### Version Strategy

This module generally follows [Semantic Versioning](http://semver.org/) for choosing an appropriate release version number with the following exception:

* Minor, for example from version 2.0.0 to 2.1.0

### Contributors

To see who's already involved, see the [list of contributors.](https://github.com/puppetlabs/puppetlabs-dsc/graphs/contributors)

## Learn More About DSC

You can learn more about PowerShell DSC from the following online resources:

- [Microsoft PowerShell Desired State Configuration Overview](https://msdn.microsoft.com/en-us/PowerShell/dsc/overview) - Starting point for DSC topics
- [Microsoft PowerShell DSC Resources page](https://msdn.microsoft.com/en-us/powershell/dsc/resources) - For more information about built-in DSC Resources
- [Microsoft PowerShell xDSCResources Github Repo](https://github.com/PowerShell/DscResources) -  For more information about xDscResources
- [Windows PowerShell Blog](http://blogs.msdn.com/b/powershell/archive/tags/dsc/) - DSC tagged posts from the Microsoft PowerShell Team
- [Puppet Inc Windows DSC & WSUS Webinar 9-17-2015 webinar](https://puppet.com/webinars/windows-dsc-wsus-webinar-09-17-2015) - How DSC works with Puppet
- [Better Together: Managing Windows with Puppet, PowerShell and DSC - PuppetConf 10-2015 talk](https://www.youtube.com/watch?v=TP0zqe-yQto) and [slides](https://speakerdeck.com/iristyle/better-together-managing-windows-with-puppet-powershell-and-dsc)
- [PowerShell.org](http://powershell.org/wp/tag/dsc/) - Community based DSC tagged posts
- [PowerShell Magazine](http://www.powershellmagazine.com/tag/dsc/) - Community based DSC tagged posts

There are several books available as well. Here are some selected books for reference:

- [Learning PowerShell DSC](http://bit.ly/learndsc) - James Pogran is a member of the team here at Puppet Inc working on the DSC/Puppet integration
- [The DSC Book](https://www.penflip.com/powershellorg/the-dsc-book) - Powershell.org community contributed content
- [Windows PowerShell Desired State Configuration Revealed](http://www.apress.com/9781484200179) - Ravikanth Chaganti

## License

* Copyright (c) 2014 Marc Sutter, original author
* Copyright (c) 2015 - Present Puppet Inc
* License: [Apache License, Version 2.0](https://github.com/puppetlabs/puppetlabs-dsc/blob/master/LICENSE)
