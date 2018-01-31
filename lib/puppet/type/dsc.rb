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

  newparam(:dsc_resource_module) do
    desc "DSC Resource Module"
    isrequired
    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty #{self.name.to_s} must be specified."
      end
      fail "#{self.name.to_s} should be a Hash or String" unless value.is_a?(Hash) || value.is_a?(String)
      if value.is_a?(Hash)
        valid_keys = ['name','version']
        unless (value.keys & valid_keys) == value.keys
          fail("Must specify name and version if using ModuleSpecification")
        end
      end
    end
  end

  newparam(:dsc_resource_properties, :array_matching => :all) do
    desc <<-HERE
    The hash of properties to pass to the DSC Resource.

    To express EmbeddedInstances, the dsc_resource_properties parameter will reconize any key with a hash value that contains two keys: dsc_type and dsc_properties, as a indication of how to format the data supplied. The dsc_type contains the CimInstance name to use, and the dsc_properties contains a hash or an array of hashes representing the data for the CimInstances. If the CimInstance is an array, we append a [] to the end of the name.
HERE
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
