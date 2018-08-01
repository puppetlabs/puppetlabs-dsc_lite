require 'puppet/util/feature'

if Puppet.features.microsoft_windows?

  DSC_LITE_MODULE_POWERSHELL_UPGRADE_MSG = <<-UPGRADE
  The dsc_lite module requires PowerShell version %{required} - current version %{current}

  The cmdlet Invoke-DscResource was introduced in v5.0, and is necessary for the
  dsc_lite module to function. Further bug fixes, first made available in version
  %{required} are also necessary for this module to function.

  To enable this module, please install the latest version of WMF 5+ from Microsoft.
  UPGRADE

  required_version = Gem::Version.new('5.0.10586.117')
  installed_version = Gem::Version.new(Facter.value(:powershell_version))

  if (installed_version >= required_version)
    Puppet.features.add(:dsc_lite)
  else
    params = [
      'dsc_lite_unavailable',
      :dsc_lite_unavailable,
      DSC_LITE_MODULE_POWERSHELL_UPGRADE_MSG %
        { :required => required_version, :current => installed_version},
      nil,
      nil
    ]

    # Puppet 5 allows changing warning to error
    params << :err if Puppet.method(:warn_once).arity > 5

    Puppet.warn_once(*params)
  end
end
