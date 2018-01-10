# dsc_lite

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

The Puppet dsc_lite module allows you to manage target nodes using Windows PowerShell DSC (Desired State Configuration) Resources.

## Windows System Prerequisites

 - At least PowerShell 5.0, which is included in [Windows Management Framework 5.0][wmf-5.0].

## Setup

~~~bash
puppet module install puppetlabs-dsc_lite
~~~

See [known issues](#known-issues) for troubleshooting setup.

## Usage

The generic `dsc` type is a streamlined and minimal representation of a DSC Resource declaration in Puppet syntax. You can use a DSC Resource by supplying the same properties you would set in a DSC Configuration script inside the `dsc_resource_properties` parameter. For most use cases the `dsc_resource_properties` parameter accepts the same structure as the PowerShell syntax, with the substitution of Puppet syntax for arrays, hashes and other data structures.

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
dsc {'foo':
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
dsc {'foouser':
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

A DSC Resource may need a more complex type than a simple key value pair, so an EmbeddedInstance is used. An EmbeddedInstance is serialized as CimInstance over the wire. In order to represent a CimInstance in the `dsc` type, we will use the `dsc_type` key to specify which CimInstance to use. If the CimInstance is an array, we append a `[]` to the end of the name.

For example, we'll create a new IIS website using the xWebSite DSC Resource, bound to port 80. We use `dsc_type` to specify a `MSFT_xWebBindingInformation` CimInstance, and append `[]` to indicate that it is an array. Note that we do this even if we are only putting a single value in `dsc_properties`.

~~~puppet
dsc {'NewWebsite':
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
dsc {'NewWebsite':
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

- For a list of tradeoffs and improvements in the dsc_lite module compared to the dsc module, see [README_Tradeoffs.md](README_Tradeoffs.md)

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

- Use of this module with the 3.8.x x86 version of Puppet is highly discouraged, though supported.  Normally, this module employs a technique to dramatically improve performance by reusing a PowerShell process to execute DSC related commands.  However, due to the Ruby 1.9.3 runtime used with the 3.8.x x86 version of Puppet, this technique must be disabled, resulting in at least a 2x slowdown.

### Known Issues

- `--noop` mode, `puppet resource` and property change notifications are currently not implemented - see [MODULES-2270](https://tickets.puppet.com/browse/MODULES-2270) for details.

### Running Puppet and DSC without Administrative Privileges

While there are avenues for using Puppet with a non-administrative account, DSC is limited to only accounts with administrative privileges. The underlying CIM implementation DSC uses for DSC Resource invocation requires administrative credentials to function.

- Using the Invoke-DscResource cmdlet requires administrative credentials

The Puppet agent on a Windows node can run DSC with a normal default install. If the Puppet agent was configured to use an alternate user account, that account must have administrative privileges on the system in order to run DSC.

## Troubleshooting

When Puppet runs, the dsc_lite module takes the code supplied in your puppet manifest and converts that into PowerShell code that is sent to the DSC engine directly using `Invoke-DscResource`. You can see both the commands sent and the result of this by running puppet interactively, e.g. `puppet apply --debug`. It will output the PowerShell code that is sent to DSC to execute and the return data from DSC. For example:

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
