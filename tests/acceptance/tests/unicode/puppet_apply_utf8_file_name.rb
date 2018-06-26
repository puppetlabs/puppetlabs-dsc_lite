require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'Apply generic DSC Manifest with UTF-8 file name to create a puppetfakeresource'

installed_path = get_dsc_resource_fixture_path(usage = :manifest)

# different UTF-8 widths
# 1-byte A
# 2-byte ۿ - http://www.fileformat.info/info/unicode/char/06ff/index.htm - 0xDB 0xBF / 219 191
# 3-byte ᚠ - http://www.fileformat.info/info/unicode/char/16A0/index.htm - 0xE1 0x9A 0xA0 / 225 154 160
# 4-byte 𠜎 - http://www.fileformat.info/info/unicode/char/2070E/index.htm - 0xF0 0xA0 0x9C 0x8E / 240 160 156 142
MIXED_UTF8 = "A\u06FF\u16A0\u{2070E}" # Aۿᚠ𠜎

# Manifest
file_name = MIXED_UTF8
file_path = SecureRandom.uuid
test_file_contents = SecureRandom.uuid
dsc_manifest = <<-MANIFEST
dsc {'some_name':
  dsc_resource_name => 'puppetfakeresource',
  # NOTE: install_fake_reboot_resource installs on master, which pluginsyncs here
  dsc_resource_module => '#{installed_path}/1.0',
  dsc_resource_properties => {
    ensure          => 'present',
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{file_path}\\#{file_name}'
  }
}
MANIFEST

# Teardown
teardown do
  step 'Remove Test Artifacts'
  windows_agents.each do |agent|
    teardown_dsc_resource_fixture(agent)
  end
  on(windows_agents, "rm -rf C:/#{file_path}")
end

# Tests
windows_agents.each do |agent|
  step 'setup'
  on(agent, powershell("mkdir /#{file_path}"))

  step 'Copy Test Type Wrappers'
  setup_dsc_resource_fixture(agent)

  step 'Run Puppet Apply'
  on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify Results'
  powershell_cmd = "'Write-Host (Get-ChildItem C:\\#{file_path}  -Filter '#{file_name}' | Measure-Object ).Count;'"
  on(agent, powershell(powershell_cmd)) do |result|
    assert('1' == result.stdout.to_s.strip, 'File with correct UTF-8 characters was not present.')
  end
end

# New manifest to remove value.
dsc_remove_manifest = <<-MANIFEST
dsc {'some_name':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module => '#{installed_path}/1.0',
  dsc_resource_properties => {
    ensure          => 'absent',
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{file_path}\\#{file_name}'
  }
}
MANIFEST

windows_agents.each do |agent|
  step 'Apply Manifest to Remove File'
  on(agent, puppet('apply'), :stdin => dsc_remove_manifest, :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify Results'
  # if the file count is greater than 0, 'absent' didn't work
  powershell_cmd = "'Write-Host (Get-ChildItem C:\\#{file_path} -Filter '#{file_name}' | Measure-Object ).Count;'"
  on(agent, powershell(powershell_cmd)) do |result|
    assert('0' == result.stdout.to_s.strip, 'File with UTF-8 character name was not removed')
  end
end
