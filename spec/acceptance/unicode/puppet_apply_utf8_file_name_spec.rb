require 'spec_helper_acceptance'

describe 'UTF-8 tests' do

# different UTF-8 widths
# 1-byte A
# 2-byte ۿ - http://www.fileformat.info/info/unicode/char/06ff/index.htm - 0xDB 0xBF / 219 191
# 3-byte ᚠ - http://www.fileformat.info/info/unicode/char/16A0/index.htm - 0xE1 0x9A 0xA0 / 225 154 160
# 4-byte 𠜎 - http://www.fileformat.info/info/unicode/char/2070E/index.htm - 0xF0 0xA0 0x9C 0x8E / 240 160 156 142
  MIXED_UTF8 = "A\u06FF\u16A0\u{2070E}" # Aۿᚠ𠜎

  file_name = MIXED_UTF8
  file_path = SecureRandom.uuid
  test_file_contents = SecureRandom.uuid

  dsc_manifest = <<-MANIFEST
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

  context 'Apply generic DSC Manifest with ensure present on UTF-8 file name to create a puppetfakeresource' do
    windows_agents.each do |agent|
      it 'Run Puppet Apply' do
        on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0, 2]) do |result|
          assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
        end
      end

      it 'Verify Results' do
        powershell_cmd = "'Write-Host (Get-ChildItem C:\\#{file_path}  -Filter '#{file_name}' | Measure-Object ).Count;'"
        on(agent, powershell(powershell_cmd)) do |result|
          assert('1' == result.stdout.to_s.strip, 'File with correct UTF-8 characters was not present.')
        end
      end
    end
  end

  context 'Apply generic DSC Manifest with ensure absent on UTF-8 file name to remove a puppetfakeresource' do
    windows_agents.each do |agent|
      it 'Apply Manifest to Remove File' do
        on(agent, puppet('apply'), :stdin => dsc_remove_manifest, :acceptable_exit_codes => [0, 2]) do |result|
          assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
        end
      end

      it 'Verify Results' do
        # if the file count is greater than 0, 'absent' didn't work
        powershell_cmd = "'Write-Host (Get-ChildItem C:\\#{file_path} -Filter '#{file_name}' | Measure-Object ).Count;'"
        on(agent, powershell(powershell_cmd)) do |result|
          assert('0' == result.stdout.to_s.strip, 'File with UTF-8 character name was not removed')
        end
      end
    end
  end

  before(:all) do
    windows_agents.each do |agent|
      on(agent, powershell("mkdir /#{file_path}"))
      setup_dsc_resource_fixture(agent)
    end
  end

  after(:all) do
    windows_agents.each do |agent|
      teardown_dsc_resource_fixture(agent)
    end
    on(windows_agents, "rm -rf C:/#{file_path}")
  end
end
