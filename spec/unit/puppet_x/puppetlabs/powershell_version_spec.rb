#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/type'
require 'puppet_x/puppetlabs/dsc_lite/powershell_version'

describe PuppetX::PuppetLabs::DscLite::PowerShellVersion, :if => Puppet::Util::Platform.windows? do
  context "detecting versions" do
  end
end
