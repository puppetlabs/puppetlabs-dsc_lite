# frozen_string_literal: true

require 'spec_helper'
require 'puppet_x'
describe Puppet::Type.type(:base_dsc_lite) do
  let :base_dsc_lite do
    Puppet::Type.type(:base_dsc_lite).new(
      name: 'foo',
    )
  end

  it 'stringifies normally' do
    expect(base_dsc_lite.to_s).to eq('Base_dsc_lite[foo]')
  end

  # Configuration PROVIDER TESTS

  describe 'powershell provider tests' do
    it 'successfully instantiate the provider' do
      described_class.provider(:powershell).new(base_dsc_lite)
    end

    before(:each) do
      @provider = described_class.provider(:powershell).new(base_dsc_lite)
    end
  end
end
