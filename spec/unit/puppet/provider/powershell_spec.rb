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

  describe "when secrets are present" do
    it "should unwrap secrets for passing to PowerShell" do
      sensitive_pass = Puppet::Pops::Types::PSensitiveType::Sensitive.new('password')
      expect(subject.class.format_dsc_value(sensitive_pass)).to match(/'password' <# PuppetSensitive #>/)
    end
    it "should redact secrets for displaying in debug" do
      # Note that here we're passing a full string as it shows up in the script_content to be executed
      # This is because we built a matcher to redact the value being passed, but not the key.
      # This means a redaction of a string not including '= ' before the string value will not redact.
      # Every secret unwrapped in this module will unwrap as "'secret' # PuppetSensitive #>" and, currently,
      # always inside a hash table to be passed along. This means we can (currently) expect the value to
      # always come after an equals sign.
      expect(subject.class.redact_content(" 'password' = 'password' <# PuppetSensitive #>\n")).not_to match(/<# PuppetSensitive #>/)
      expect(subject.class.redact_content(" 'password' = 'password' <# PuppetSensitive #>\n")).to match(/'password' = '\[REDACTED\]'/)
      expect(subject.class.redact_content("'user' = 'username' <# PuppetSensitive #> ; 'password' = 'passwordz' <# PuppetSensitive #>\n")).not_to match(/(username|passwordz)/)
    end
  end
end
