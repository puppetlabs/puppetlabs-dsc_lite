require 'spec_helper'
require 'puppet/type'
require 'puppet/type/dsc'

describe Puppet::Type.type(:dsc) do
  let(:resource) {
    described_class.new(
      :name => "dsc",
      :resource_name => 'foo',
      :module => 'bar',
      :properties => { 'wakka' => 'woot' }
    )
  }
  subject { resource }

  it { is_expected.to be_a_kind_of Puppet::Type::Dsc }

  describe "type" do
    it "should be built dynamically from parameter :resource_name" do
      expect(resource.type).to eq(:Dsc_lite_foo)
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

    it "deserializes and munges malformed sensitive values for Puppet 5" do
      value = SecureRandom.uuid
      munged = Puppet::Type.type(:dsc).new(
        :title => 'foo',
        :properties => {
          "bar" => {"__ptype" => "Sensitive", "__pvalue" => value},
          "bar2" => {
            "bar3" => {"__ptype" => "Sensitive", "__pvalue" => value},
          },
        },
        :resource_name => "baz",
        :module => "cat",
      )
      expect(munged[:properties]["bar"]).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(munged[:properties]["bar"].unwrap).to eq value
      expect(munged[:properties]["bar2"]["bar3"]).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(munged[:properties]["bar2"]["bar3"].unwrap).to eq value
    end

    it "deserializes and munges malformed sensitive values for Puppet 6" do
      value = SecureRandom.uuid
      munged = Puppet::Type.type(:dsc).new(
        :title => 'foo',
        :properties => {
          "bar" => {"__pcore_type__" => "Sensitive", "__pcore_value__" => value},
          "bar2" => {
            "bar3" => {"__pcore_type__" => "Sensitive", "__pcore_value__" => value},
          },
        },
        :resource_name => "baz",
        :module => "cat",
      )
      expect(munged[:properties]["bar"]).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(munged[:properties]["bar"].unwrap).to eq value
      expect(munged[:properties]["bar2"]["bar3"]).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(munged[:properties]["bar2"]["bar3"].unwrap).to eq value
    end
  end
end
