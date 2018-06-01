require 'spec_helper'
require 'puppet_x/puppetlabs/dsc_lite/dsc_type_helpers'

describe PuppetX::DscLite::TypeHelpers do
  describe "#validate_MSFT_Credential" do

    it "should allow plaintext strings as passwords" do
      cred = { 'user' => 'bob', 'password' => 'password' }
      expect {
        subject.class.validate_MSFT_Credential('foo', cred)
      }.to_not raise_error
    end

    it "should allow Sensitive type passwords" do
      sensitive_pass = Puppet::Pops::Types::PSensitiveType::Sensitive.new('password')
      cred = { 'user' => 'bob', 'password' => sensitive_pass }
      expect {
        subject.class.validate_MSFT_Credential('foo', cred)
      }.to_not raise_error
    end
  end
end
