require 'spec_helper'
require 'puppet/type'
require 'puppet/type/dsc'

describe Puppet::Type.type(:dsc) do
  let(:resource) { described_class.new(:name => "dsc") }
  subject { resource }

  it { is_expected.to be_a_kind_of Puppet::Type::Dsc }

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

  describe "parameter :dsc_resource_name" do
    subject { resource.parameters[:dsc_resource_name] }

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

  describe "parameter :dsc_resource_module" do
    subject { resource.parameters[:dsc_resource_module] }

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

  describe "parameter :dsc_resource_properties" do
    subject { resource.parameters[:dsc_resource_properties] }

    it "should not allow nil" do
      expect {
        resource[:dsc_resource_properties] = nil
      }.to raise_error(Puppet::Error, /Got nil value for dsc_resource_properties/)
    end

    it "should not allow empty" do
      expect {
        resource[:dsc_resource_properties] = ''
      }.to raise_error(Puppet::ResourceError, /A non-empty dsc_resource_properties must be specified/)
    end

    it "requires a hash or array of hashes" do
      expect {
        resource[:dsc_resource_properties] = "hi"
      }.to raise_error(Puppet::Error, /dsc_resource_properties should be a Hash/)
      expect {
        resource[:dsc_resource_properties] = ["hi"]
      }.to raise_error(Puppet::Error, /dsc_resource_properties should be a Hash/)
    end
  end
end
