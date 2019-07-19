require 'spec_helper_acceptance'

describe 'UTF-8' do
  # different UTF-8 widths
  # 1-byte A
  # 2-byte ۿ - http://www.fileformat.info/info/unicode/char/06ff/index.htm - 0xDB 0xBF / 219 191
  # 3-byte ᚠ - http://www.fileformat.info/info/unicode/char/16A0/index.htm - 0xE1 0x9A 0xA0 / 225 154 160
  # 4-byte 𠜎 - http://www.fileformat.info/info/unicode/char/2070E/index.htm - 0xF0 0xA0 0x9C 0x8E / 240 160 156 142
  MIXED_UTF8 = "A\u06FF\u16A0\u{2070E}".freeze # Aۿᚠ𠜎

  file_name = MIXED_UTF8
  file_path = SecureRandom.uuid
  test_file_contents = SecureRandom.uuid

  dsc_create_manifest = <<-MANIFEST
    dsc {'some_name':
      resource_name => 'puppetfakeresource',
      # NOTE: install_fake_reboot_resource installs on master, which pluginsyncs here
      module => '#{installed_path}/1.0',
      properties => {
        ensure          => 'present',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{file_path}\\#{file_name}'
      }
    }
  MANIFEST

  dsc_remove_manifest = <<-MANIFEST
    dsc {'some_name':
      resource_name => 'puppetfakeresource',
      module => '#{installed_path}/1.0',
      properties => {
        ensure          => 'absent',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{file_path}\\#{file_name}'
      }
    }
  MANIFEST

  before(:all) do
    windows_agents.each do |agent|
      on(agent, powershell("mkdir /#{file_path}"))
      create_remote_file(agent, "/cygdrive/c/#{file_path}/dsc_create_manifest.pp", dsc_create_manifest)
      create_remote_file(agent, "/cygdrive/c/#{file_path}/dsc_remove_manifest.pp", dsc_remove_manifest)
      setup_dsc_resource_fixture(agent)
    end
  end

  after(:all) do
    windows_agents.each do |agent|
      teardown_dsc_resource_fixture(agent)
    end
    on(windows_agents, "rm -rf C:/#{file_path}")
  end

  context 'create DSC resource with ensure present on UTF-8 file name' do
    windows_agents.each do |agent|
      it 'applies manifest' do
        on(agent, puppet("apply C:\\\\#{file_path}\\\\dsc_create_manifest.pp --detailed-exitcodes"), acceptable_exit_codes: [0, 2]) do |result|
          expect(result.stderr).not_to match(%r{Error:})
        end
      end

      it 'creates file' do
        powershell_cmd = "'Write-Host (Get-ChildItem C:\\#{file_path}  -Filter '#{file_name}' | Measure-Object ).Count;'"
        on(agent, powershell(powershell_cmd)) do |result|
          expect(result.stdout.to_s.strip).to eq('1')
        end
      end
    end
  end

  context 'remove DSC resource contains ensure absent on UTF-8 file name' do
    windows_agents.each do |agent|
      it 'applies manifest' do
        on(agent, puppet("apply C:\\\\#{file_path}\\\\dsc_remove_manifest.pp --detailed-exitcodes"), acceptable_exit_codes: [0, 2]) do |result|
          expect(result.stderr).not_to match(%r{Error:})
        end
      end

      it 'removes file' do
        expect(file("C:\\#{file_path}\\#{file_name}")).not_to exist
      end
    end
  end
end
