#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/type'
require 'puppet/type/base_dsc_lite'

describe Puppet::Type.type(:base_dsc_lite).provider(:powershell) do

  it "should be an instance of Puppet::Type::base_dsc_lite::ProviderPowershell" do
    subject.must be_an_instance_of Puppet::Type::Base_dsc_lite::ProviderPowershell
  end

  describe "when quotes are present" do

    it "should handle single quotes" do
      expect(subject.class.format_dsc_value("The 'Cats' go 'meow'!")).to match(/'The ''Cats'' go ''meow''!'/)
    end

    it "should handle double single quotes" do
      expect(subject.class.format_dsc_value("The ''Cats'' go 'meow'!")).to match(/'The ''''Cats'''' go ''meow''!'/)
    end

    it "should handle double quotes" do
      expect(subject.class.format_dsc_value("The 'Cats' go \"meow\"!")).to match(/'The ''Cats'' go "meow"!'/)
    end

    it "should handle dollar signs" do
      expect(subject.class.format_dsc_value("This should show \$foo variable")).to match(/'This should show \$foo variable'/)
    end
  end
end
