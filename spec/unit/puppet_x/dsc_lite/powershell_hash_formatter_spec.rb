# frozen_string_literal: true

# rubocop:disable RSpec/FilePath
require 'spec_helper'
require 'puppet_x'
require 'puppet_x/puppetlabs/dsc_lite/powershell_hash_formatter'
require 'puppet/type'

describe PuppetX::PuppetLabs::DscLite::PowerShellHashFormatter do
  let(:formatter) do
    described_class
  end

  describe 'formatting ruby hash to powershell hash string' do
    describe 'when given correct hash' do
      it 'outputs correct syntax with simple example' do
        expected = <<-HERE
@{
'ensure' = 'present';
'name' = 'Web-WebServer'
}
        HERE
        result = formatter.format('ensure' => 'present',
                                  'name' => 'Web-WebServer')
        expect(result).to eq expected.strip
      end

      it 'outputs correct syntax with single CimInstance for a CimInstance[] type' do
        expected = <<-HERE
@{
'ensure' = 'Present';
'name' = 'foo';
'state' = 'Started';
'physicalpath' = 'c:/inetpub/wwwroot';
'bindinginfo' = [CimInstance[]]@(
(New-CimInstance -ClassName 'MSFT_xWebBindingInformation' -ClientOnly -Property @{
'protocol' = 'HTTP';
'port' = 80
})
)
}
        HERE

        result = formatter.format('ensure' => 'Present',
                                  'name' => 'foo',
                                  'state' => 'Started',
                                  'physicalpath' => 'c:/inetpub/wwwroot',
                                  'bindinginfo' => {
                                    'dsc_type' => 'MSFT_xWebBindingInformation[]',
                                    'dsc_properties' => {
                                      'protocol' => 'HTTP',
                                      'port' => 80
                                    }
                                  })

        expect(result).to eq expected.strip
      end

      it 'outputs correct syntax with single CimInstance for a CimInstance type' do
        expected = <<-HERE
@{
'ensure' = 'Present';
'name' = 'foo';
'state' = 'Started';
'physicalpath' = 'c:/inetpub/wwwroot';
'authenticationinfo' = [CimInstance](New-CimInstance -ClassName 'MSFT_xWebAuthenticationInformation' -ClientOnly -Property @{
'anonymous' = $true;
'basic' = $false;
'windows' = $true;
'digest' = $false
})
}
        HERE

        result = formatter.format('ensure' => 'Present',
                                  'name' => 'foo',
                                  'state' => 'Started',
                                  'physicalpath' => 'c:/inetpub/wwwroot',
                                  'authenticationinfo' => {
                                    'dsc_type' => 'MSFT_xWebAuthenticationInformation',
                                    'dsc_properties' => {
                                      'anonymous' => true,
                                      'basic' => false,
                                      'windows' => true,
                                      'digest' => false
                                    }
                                  })

        expect(result).to eq expected.strip
      end

      it 'outputs correct syntax with array CimInstance' do
        expected = <<-HERE
@{
'ensure' = 'Present';
'name' = 'foo';
'state' = 'Started';
'physicalpath' = 'c:/inetpub/wwwroot';
'bindinginfo' = [CimInstance[]]@(
(New-CimInstance -ClassName 'MSFT_xWebBindingInformation' -ClientOnly -Property @{
'protocol' = 'HTTP';
'port' = 80
}),
(New-CimInstance -ClassName 'MSFT_xWebBindingInformation' -ClientOnly -Property @{
'protocol' = 'HTTPS';
'port' = 443;
'certificatethumbprint' = '5438DC0CB31B1C91B8945C7D91B3338F9C08BEFA';
'certificatestorename' = 'My';
'ipaddress' = '*'
})
)
}
        HERE

        result = formatter.format('ensure' => 'Present',
                                  'name' => 'foo',
                                  'state' => 'Started',
                                  'physicalpath' => 'c:/inetpub/wwwroot',
                                  'bindinginfo' => {
                                    'dsc_type' => 'MSFT_xWebBindingInformation[]',
                                    'dsc_properties' => [
                                      {
                                        'protocol' => 'HTTP',
                                        'port' => 80
                                      },
                                      {
                                        'protocol' => 'HTTPS',
                                        'port' => 443,
                                        'certificatethumbprint' => '5438DC0CB31B1C91B8945C7D91B3338F9C08BEFA',
                                        'certificatestorename' => 'My',
                                        'ipaddress' => '*'
                                      },
                                    ]
                                  })

        expect(result).to eq expected.strip
      end

      it 'outputs correct syntax with a PSCredential' do
        expected = <<-HERE
@{
'username' = 'jane-doe';
'description' = 'Jane Doe user';
'ensure' = 'present';
'password' = ([PSCustomObject]@{
'user' = 'jane-doe';
'password' = 'jane-password'
} | new-pscredential);
'passwordneverexpires' = $false;
'disabled' = $true
}
        HERE
        result = formatter.format('username' => 'jane-doe',
                                  'description' => 'Jane Doe user',
                                  'ensure' => 'present',
                                  'password' => {
                                    'dsc_type' => 'MSFT_Credential',
                                    'dsc_properties' => {
                                      'user' => 'jane-doe',
                                      'password' => 'jane-password'
                                    }
                                  },
                                  'passwordneverexpires' => false,
                                  'disabled' => true)
        expect(result).to eq expected.strip
      end

      it 'outputs correct syntax with MSFT_KeyValuePair' do
        expected = <<-HERE
@{
'destinationPath' = 'c:\fileName.jpg';
'uri' = 'http://www.contoso.com/image.jpg';
'userAgent' = '[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer';
'headers' = @{
'Accept-Language' = 'en-US'
}
}
        HERE
        result = formatter.format('destinationPath' => "c:\fileName.jpg",
                                  'uri' => 'http://www.contoso.com/image.jpg',
                                  'userAgent' => '[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer',
                                  'headers' => {
                                    'Accept-Language' => 'en-US'
                                  })
        expect(result).to eq expected.strip
      end

      it 'outputs correct syntax with Sensitive MSFT_Credential' do
        expected = <<-HERE
@{
'username' = 'jane-doe';
'description' = 'Jane Doe user';
'ensure' = 'present';
'password' = ([PSCustomObject]@{
'user' = 'jane-doe';
'password' = 'password' # PuppetSensitive
} | new-pscredential);
'passwordneverexpires' = $false;
'disabled' = $true
}
        HERE
        sensitive_pass = Puppet::Pops::Types::PSensitiveType::Sensitive.new('password')
        result = formatter.format('username' => 'jane-doe',
                                  'description' => 'Jane Doe user',
                                  'ensure' => 'present',
                                  'password' => {
                                    'dsc_type' => 'MSFT_Credential',
                                    'dsc_properties' => {
                                      'user' => 'jane-doe',
                                      'password' => sensitive_pass
                                    }
                                  },
                                  'passwordneverexpires' => false,
                                  'disabled' => true)
        expect(result).to eq expected.strip
      end
    end
  end
end
