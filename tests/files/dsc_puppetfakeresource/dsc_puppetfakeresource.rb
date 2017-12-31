require 'pathname'

Puppet::Type.newtype(:dsc_puppetfakeresource) do
  require Pathname.new(__FILE__).dirname + '../../' + 'puppet/type/base_dsc_lite'
  require Pathname.new(__FILE__).dirname + '../../puppet_x/puppetlabs/dsc_lite/dsc_type_helpers'

  @doc = %q{
    The DSC PuppetFakeResource resource type.
    Automatically generated from
    'PuppetFakeResource/DSCResources/PuppetFakeResource/PuppetFakeResource.schema.mof'

    To learn more about PowerShell Desired State Configuration, please
    visit https://technet.microsoft.com/en-us/library/dn249912.aspx.

    For more information about built-in DSC Resources, please visit
    https://technet.microsoft.com/en-us/library/dn249921.aspx.

    For more information about xDsc Resources, please visit
    https://github.com/PowerShell/DscResources.
  }

  validate do
      fail('dsc_importantstuff is a required attribute') if self[:dsc_importantstuff].nil?
    end

  def dscmeta_resource_friendly_name; 'PuppetFakeResource' end
  def dscmeta_resource_name; 'PuppetFakeResource' end
  def dscmeta_module_name; 'PuppetFakeResource' end
  def dscmeta_module_version; '1.0' end

  newparam(:name, :namevar => true ) do
  end

  ensurable do
    newvalue(:exists?) { provider.exists? }
    newvalue(:present) { provider.create }
    newvalue(:absent)  { provider.destroy }
    defaultto { :present }
  end

  # Name:         Ensure
  # Type:         string
  # IsMandatory:  False
  # Values:       ["Present", "Absent"]
  newparam(:dsc_ensure) do
    def mof_type; 'string' end
    def mof_is_embedded?; false end
    desc "Ensure - Ensure Present or Absent Valid values are Present, Absent."
    validate do |value|
      resource[:ensure] = value.downcase
      unless value.kind_of?(String)
        fail("Invalid value '#{value}'. Should be a string")
      end
      unless ['Present', 'present', 'Absent', 'absent'].include?(value)
        fail("Invalid value '#{value}'. Valid values are Present, Absent")
      end
    end
  end

  # Name:         ImportantStuff
  # Type:         string
  # IsMandatory:  True
  # Values:       None
  newparam(:dsc_importantstuff) do
    def mof_type; 'string' end
    def mof_is_embedded?; false end
    desc "ImportantStuff - Important Stuff"
    isrequired
    validate do |value|
      unless value.kind_of?(String)
        fail("Invalid value '#{value}'. Should be a string")
      end
    end
  end

  # Name:         RequireReboot
  # Type:         boolean
  # IsMandatory:  False
  # Values:       None
  newparam(:dsc_requirereboot) do
    def mof_type; 'boolean' end
    def mof_is_embedded?; false end
    desc "RequireReboot"
    validate do |value|
    end
    newvalues(true, false)
    munge do |value|
      PuppetX::DscLite::TypeHelpers.munge_boolean(value.to_s)
    end
  end

  # Name:         ThrowMessage
  # Type:         string
  # IsMandatory:  False
  # Values:       None
  newparam(:dsc_throwmessage) do
    def mof_type; 'string' end
    def mof_is_embedded?; false end
    desc "ThrowMessage - If set to non-empty causes PowerShell to throw an error on set"
    validate do |value|
      unless value.kind_of?(String)
        fail("Invalid value '#{value}'. Should be a string")
      end
    end
  end

  def builddepends
    pending_relations = super()
    PuppetX::DscLite::TypeHelpers.ensure_reboot_relationship(self, pending_relations)
  end
end

Puppet::Type.type(:dsc_puppetfakeresource).provide :powershell, :parent => Puppet::Type.type(:base_dsc_lite).provider(:powershell) do
  confine :true => (Gem::Version.new(Facter.value(:powershell_version)) >= Gem::Version.new('5.0.10240.16384'))
  defaultfor :operatingsystem => :windows

  mk_resource_methods
end
