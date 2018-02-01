#!/usr/bin/env ruby
require 'spec_helper'

describe Puppet::Type.type(:base_dsc_lite) do

  let :base_dsc_lite do
    Puppet::Type.type(:base_dsc_lite).new(
      :name     => 'foo',
    )
  end

  it "should stringify normally" do
    expect(base_dsc_lite.to_s).to eq("Base_dsc_lite[foo]")
  end

  # Configuration PROVIDER TESTS

  describe "powershell provider tests" do

    it "should successfully instantiate the provider" do
      described_class.provider(:powershell).new(base_dsc_lite)
    end

    before(:each) do
      @provider = described_class.provider(:powershell).new(base_dsc_lite)
    end

  end

end
