require 'pathname'

Puppet::Type.newtype(:dsc) do
  require Pathname.new(__FILE__).dirname + '../../' + 'puppet/type/base_dsc_lite'
  require Pathname.new(__FILE__).dirname + '../../puppet_x/puppetlabs/dsc_lite/dsc_type_helpers'

  ensurable do
    desc <<-HERE
    An optional property that specifies that the DSC resource should be invoked.
    This property has only one value of `present`.
    This property does not need be be set in manifests.
HERE
    # Using the default magic of puppet to run exists? to detmine if create should be called
    # means that by default puppet will think of the resource as 'present' if the dsc resource
    # is in the desired state. Setting this to a more semantically correct name, such as 
    # `invoke` will cause puppet to report the resource changing from 'present' to 'invoke'
    # on every run where changes are not actually made. In any case, puppet will always report
    # that the resource was created on runs where Invoke-DscResource _does_ modify the system.
    newvalue(:present) { provider.create }
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

  newparam(:resource_name) do
    desc "DSC Resource Name"
    isrequired
    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty #{self.name.to_s} must be specified."
      end
      fail "#{self.name.to_s} should be a String" unless value.is_a? ::String
    end
  end

  newparam(:module) do
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

  newparam(:properties, :array_matching => :all) do
    desc <<-HERE
    The hash of properties to pass to the DSC Resource.

    To express EmbeddedInstances, the properties parameter will reconize any key with a hash value that contains two keys: dsc_type and dsc_properties, as a indication of how to format the data supplied. The dsc_type contains the CimInstance name to use, and the dsc_properties contains a hash or an array of hashes representing the data for the CimInstances. If the CimInstance is an array, we append a [] to the end of the name.
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
  confine :feature => :dsc_lite
  defaultfor :operatingsystem => :windows

  mk_resource_methods
end
