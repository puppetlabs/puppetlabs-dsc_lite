require 'spec_helper'
require 'puppet/type'
require 'puppet/type/dsc'

describe Puppet::Type.type(:dsc) do
  let(:resource) { described_class.new(:name => "dsc") }
  subject { resource }

  it { is_expected.to be_a_kind_of Puppet::Type::Dsc }

  describe "type" do
    it "should be built dynamically from parameter :resource_name" do
      resource[:resource_name] = 'foo'
      expect(resource.type).to eq(:Dsc_lite_foo)
    end

    it "should return Dsc_lite_unspecified given a missing :resource_name" do
      expect(resource.type).to eq(:Dsc_lite_unspecified)
    end

    it "should return Dsc_lite_unspecified given a :resource_name of ' '" do
      resource[:resource_name] = ' '
      expect(resource.type).to eq(:Dsc_lite_unspecified)
    end
  end

  describe "parameter :name" do
    subject { resource.parameters[:name] }

    it { is_expected.to be_isnamevar }

    it "should not allow nil" do
      expect {
        resource[:name] = nil
      }.to raise_error(Puppet::Error, /Got nil value for name/)
    end

    it "should not allow empty" do
      expect {
        resource[:name] = ''
      }.to raise_error(Puppet::ResourceError, /A non-empty name must/)
    end

    [ 'value', 'value with spaces', 'UPPER CASE', '0123456789_-', 'With.Period' ].each do |value|
      it "should accept '#{value}'" do
        expect { resource[:name] = value }.not_to raise_error
      end
    end

    [ '*', '()', '[]', '!@' ].each do |value|
      it "should reject '#{value}'" do
        expect { resource[:name] = value }.to raise_error(Puppet::ResourceError, /is not a valid name/)
      end
    end
  end

  describe "parameter :resource_name" do
    subject { resource.parameters[:resource_name] }
    
    it "should not allow nil" do
      expect {
        resource[:name] = nil
      }.to raise_error(Puppet::Error, /Got nil value for name/)
    end

    it "should not allow empty" do
      expect {
        resource[:name] = ''
      }.to raise_error(Puppet::ResourceError, /A non-empty name must/)
    end
    
    [ 'value', 'value with spaces', 'UPPER CASE', '0123456789_-', 'With.Period' ].each do |value|
      it "should accept '#{value}'" do
        expect { resource[:name] = value }.not_to raise_error
      end
    end

    [ '*', '()', '[]', '!@' ].each do |value|
      it "should reject '#{value}'" do
        expect { resource[:name] = value }.to raise_error(Puppet::ResourceError, /is not a valid name/)
      end
    end
  end
  
  describe "parameter :module" do
    subject { resource.parameters[:module] }
    
    it "should allow a string" do
      expect {
        resource[:module] = 'foo'
      }
    end

    it "should allow a hash" do
      expect {
        resource[:module] = { 'name' => 'bar', 'version' => '1.8' }
      }.not_to raise_error
    end

    it "should require name and version keys if hash" do
      expect {
        resource[:module] = { 'foo' => 'bar'}
      }.to raise_error(Puppet::Error, /Must specify name and version if using ModuleSpecification/)
    end

    it "should not allow nil" do
      expect {
        resource[:module] = nil
      }.to raise_error(Puppet::Error, /Got nil value for module/)
    end

    it "should not allow empty" do
      expect {
        resource[:module] = ''
      }.to raise_error(Puppet::ResourceError, /A non-empty module must/)
    end
    
    [ 'value', 'value with spaces', 'UPPER CASE', '0123456789_-', 'With.Period' ].each do |value|
      it "should accept '#{value}'" do
        expect { resource[:module] = value }.not_to raise_error
      end
    end
  end
  
  describe "parameter :properties" do
    subject { resource.parameters[:properties] }
    
    it "should not allow nil" do
      expect {
        resource[:properties] = nil
      }.to raise_error(Puppet::Error, /Got nil value for properties/)
    end

    it "should not allow empty" do
      expect {
        resource[:properties] = ''
      }.to raise_error(Puppet::ResourceError, /A non-empty properties must be specified/)
    end
    
    it "requires a hash or array of hashes" do
      expect {
        resource[:properties] = "hi"
      }.to raise_error(Puppet::Error, /properties should be a Hash/)
      expect {
        resource[:properties] = ["hi"]
      }.to raise_error(Puppet::Error, /properties should be a Hash/)
    end
  end
end
