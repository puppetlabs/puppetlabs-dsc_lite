#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/type'
require 'puppet_x/puppetlabs/dsc_lite/powershell_hash_formatter'

describe PuppetX::PuppetLabs::DscLite::PowerShellHashFormatter do
  before(:each) do
    @formatter = PuppetX::PuppetLabs::DscLite::PowerShellHashFormatter
  end

  describe "formatting ruby hash to powershell hash string" do

    describe "when given correct hash" do

      it "should output correct syntax with simple example" do
        foo = <<-HERE
@{
'ensure' = 'present';
'name' = 'Web-WebServer'
}
HERE
        result = @formatter.format({
            "ensure"      => "present",
            "name"      => "Web-WebServer",
        })
        expect(result).to eq foo.strip
      end

      it "should output correct syntax with CimInstance" do
        foo = <<-HERE
@{
'ensure' = 'Present';
'bindinginfo' = @{
'dsc_type' = 'MSFT_xWebBindingInformation[]';
'dsc_properties' = @{
'protocol' = 'HTTP';
'port' = '80'
}
}
}
HERE
        result = @formatter.format({
          "ensure"      => "Present",
          "bindinginfo" => {
            "dsc_type"       => "MSFT_xWebBindingInformation[]",
            "dsc_properties" => {
              "protocol" => "HTTP",
              "port"     => "80"
            }
          }
        })
        expect(result).to eq foo.strip
      end
    end
  end
end
