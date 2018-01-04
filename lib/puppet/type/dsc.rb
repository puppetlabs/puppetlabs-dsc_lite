require 'pathname'

Puppet::Type.newtype(:dsc) do
  require Pathname.new(__FILE__).dirname + '../../' + 'puppet/type/base_dsc_lite'
  require Pathname.new(__FILE__).dirname + '../../puppet_x/puppetlabs/dsc_lite/dsc_type_helpers'

  ensurable do
    newvalue(:exists?) { provider.exists? }
    newvalue(:present) { provider.create }
    newvalue(:absent)  { provider.destroy }
    defaultto { :present }
  end

  newparam(:name, :namevar => true) do
    desc "Name of the declaration"
    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty #{self.name.to_s} must be specified."
      end
      fail("#{value} is not a valid #{self.name.to_s}") unless value =~ /^[a-zA-Z0-9\.\-\_\'\s]+$/
    end
  end
  
  newparam(:dsc_resource_name) do
    desc "DSC Resource Name"
    isrequired
    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty #{self.name.to_s} must be specified."
      end
      fail "#{self.name.to_s} should be a String" unless value.is_a? ::String
    end
  end

  newparam(:dsc_resource_module_name) do
    desc "DSC Resource Module Name"
    isrequired
    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty #{self.name.to_s} must be specified."
      end
      fail "#{self.name.to_s} should be a String" unless value.is_a? ::String
    end
  end

  newparam(:dsc_resource_properties, :array_matching => :all) do
    desc "DSC Resource Properties"
    isrequired
    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty #{self.name.to_s} must be specified."
      end
      fail "#{self.name.to_s} should be a Hash" unless value.is_a? ::Hash
    end
  end
end

Puppet::Type.type(:dsc).provide :powershell, :parent => Puppet::Type.type(:base_dsc_lite).provider(:powershell) do
  confine :true => (Gem::Version.new(Facter.value(:powershell_version)) >= Gem::Version.new('5.0.10586.117'))
  defaultfor :operatingsystem => :windows

  mk_resource_methods
end
