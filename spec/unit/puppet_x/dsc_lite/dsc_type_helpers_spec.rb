# rubocop:disable RSpec/FilePath
require 'spec_helper'
require 'puppet_x/puppetlabs/dsc_lite/dsc_type_helpers'

describe PuppetX::DscLite::TypeHelpers do
  describe '#validate_MSFT_Credential' do
    it 'allows plaintext strings as passwords' do
      cred = { 'user' => 'bob', 'password' => 'password' }
      expect {
        described_class.validate_MSFT_Credential('foo', cred)
      }.not_to raise_error
    end

    it 'allows Sensitive type passwords' do
      sensitive_pass = Puppet::Pops::Types::PSensitiveType::Sensitive.new('password')
      cred = { 'user' => 'bob', 'password' => sensitive_pass }
      expect {
        described_class.validate_MSFT_Credential('foo', cred)
      }.not_to raise_error
    end
  end
end
