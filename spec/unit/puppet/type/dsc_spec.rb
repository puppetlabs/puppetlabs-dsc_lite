# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type'
require 'puppet/type/dsc'

# borrowed from
# https://github.com/puppetlabs/puppet/blob/363f22b2a4125bedb88921d64b277d6f8adbbef2/spec/lib/puppet_spec/compiler.rb#L4-L8
def compile_to_catalog(string, node = Puppet::Node.new('test'))
  Puppet[:code] = string
  # see lib/puppet/indirector/catalog/compiler.rb#filter
  Puppet::Parser::Compiler.compile(node).filter { |r| r.virtual? }
end

describe Puppet::Type.type(:dsc) do
  subject { resource }

  let(:resource) do
    described_class.new(
      name: 'dsc',
      resource_name: 'foo',
      module: 'bar',
      properties: { 'wakka' => 'woot' },
    )
  end

  it { is_expected.to be_a_kind_of Puppet::Type::Dsc }

  describe 'type' do
    it 'is built dynamically from parameter :resource_name' do
      expect(resource.type).to eq(:Dsc_lite_foo)
    end
  end

  describe 'parameter :name' do
    subject { resource.parameters[:name] }

    it { is_expected.to be_isnamevar }

    it 'does not allow nil' do
      expect {
        resource[:name] = nil
      }.to raise_error(Puppet::Error, %r{Got nil value for name})
    end

    it 'does not allow empty' do
      expect {
        resource[:name] = ''
      }.to raise_error(Puppet::ResourceError, %r{A non-empty name must})
    end

    ['value', 'value with spaces', 'UPPER CASE', '0123456789_-', 'With.Period', 'With=Special,Chars'].each do |value|
      it "accepts '#{value}'" do
        expect { resource[:name] = value }.not_to raise_error
      end
    end
  end

  describe 'parameter :resource_name' do
    subject { resource.parameters[:resource_name] }

    it 'does not allow nil' do
      expect {
        resource[:resource_name] = nil
      }.to raise_error(Puppet::Error, %r{Got nil value for resource_name})
    end

    it 'does not allow empty' do
      expect {
        resource[:resource_name] = ''
      }.to raise_error(Puppet::ResourceError, %r{A non-empty resource_name must})
    end

    ['value', 'value with spaces', 'UPPER CASE', '0123456789_-', 'With.Period'].each do |value|
      it "accepts '#{value}'" do
        expect { resource[:resource_name] = value }.not_to raise_error
      end
    end
  end

  describe 'parameter :module' do
    subject { resource.parameters[:module] }

    it 'allows a string' do
      expect {
        resource[:module] = 'foo'
      }.not_to raise_error
    end

    it 'allows a hash' do
      expect {
        resource[:module] = { 'name' => 'bar', 'version' => '1.8' }
      }.not_to raise_error
    end

    it 'requires name and version keys if hash' do
      expect {
        resource[:module] = { 'foo' => 'bar' }
      }.to raise_error(Puppet::Error, %r{Must specify name and version if using ModuleSpecification})
    end

    it 'does not allow nil' do
      expect {
        resource[:module] = nil
      }.to raise_error(Puppet::Error, %r{Got nil value for module})
    end

    it 'does not allow empty' do
      expect {
        resource[:module] = ''
      }.to raise_error(Puppet::ResourceError, %r{A non-empty module must})
    end

    ['value', 'value with spaces', 'UPPER CASE', '0123456789_-', 'With.Period'].each do |value|
      it "accepts '#{value}'" do
        expect { resource[:module] = value }.not_to raise_error
      end
    end
  end

  describe 'parameter :properties' do
    subject { resource.parameters[:properties] }

    it 'does not allow nil' do
      expect {
        resource[:properties] = nil
      }.to raise_error(Puppet::Error, %r{Got nil value for properties})
    end

    it 'does not allow empty' do
      expect {
        resource[:properties] = ''
      }.to raise_error(Puppet::ResourceError, %r{A non-empty properties must be specified})
    end

    it 'requires a hash or array of hashes' do
      expect {
        resource[:properties] = 'hi'
      }.to raise_error(Puppet::Error, %r{properties should be a Hash})
      expect {
        resource[:properties] = ['hi']
      }.to raise_error(Puppet::Error, %r{properties should be a Hash})
    end

    it 'deserializes and munges malformed sensitive values for Puppet 5' do
      value = SecureRandom.uuid
      munged = Puppet::Type.type(:dsc).new(
        title: 'foo',
        properties: {
          'bar' => { '__ptype' => 'Sensitive', '__pvalue' => value },
          'bar2' => {
            'bar3' => { '__ptype' => 'Sensitive', '__pvalue' => value },
          },
        },
        resource_name: 'baz',
        module: 'cat',
      )
      expect(munged[:properties]['bar']).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(munged[:properties]['bar'].unwrap).to eq value
      expect(munged[:properties]['bar2']['bar3']).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(munged[:properties]['bar2']['bar3'].unwrap).to eq value
    end

    it 'deserializes and munges malformed sensitive values for Puppet 6' do
      value = SecureRandom.uuid
      munged = Puppet::Type.type(:dsc).new(
        title: 'foo',
        properties: {
          'bar' => { '__pcore_type__' => 'Sensitive', '__pcore_value__' => value },
          'bar2' => {
            'bar3' => { '__pcore_type__' => 'Sensitive', '__pcore_value__' => value },
          },
        },
        resource_name: 'baz',
        module: 'cat',
      )
      expect(munged[:properties]['bar']).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(munged[:properties]['bar'].unwrap).to eq value
      expect(munged[:properties]['bar2']['bar3']).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(munged[:properties]['bar2']['bar3'].unwrap).to eq value
    end

    it 'compiles references to deferred functions into a catalog' do
      catalog = compile_to_catalog(<<~END)
        dsc {'foo':
          resource_name => 'WindowsFoo',
          properties    => {
            password => Deferred("join", [[1,2,3], ':']),
          }
        }
      END

      expect(catalog.resource(:dsc, 'foo')[:properties]['password'].arguments).to eq([[1, 2, 3], ':'])
    end
  end
end
