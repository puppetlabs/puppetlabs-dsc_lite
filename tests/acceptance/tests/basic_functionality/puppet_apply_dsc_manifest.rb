require 'erb'
require 'dsc_utils'
require 'securerandom'
test_name 'FM-2625 - C68511 - Apply DSC Resource Manifest via "puppet apply"'

installed_path = get_dsc_resource_fixture_path(usage = :manifest)

# ERB Manifest
test_dir_path = SecureRandom.uuid
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
file { 'C:/#{ test_dir_path }' :
   ensure => 'directory'
}
->
dsc { '#{fake_name}':
  resource_name => 'puppetfakeresource',
  module => '#{installed_path}/1.0',
  properties => {
    ensure          => 'present',
    importantstuff  => '#{test_file_contents}',
    destinationpath => '#{"C:\\" + test_dir_path + "\\" + fake_name}',
  },
}
MANIFEST

# Teardown
teardown do
  step 'Remove Test Artifacts'
  on(windows_agents, "rm -rf /cygdrive/c/#{test_dir_path}")
  windows_agents.each do |agent|
    teardown_dsc_resource_fixture(agent)
  end
end

# Tests
windows_agents.each do |agent|
  step 'Copy Test Type Wrappers'
  setup_dsc_resource_fixture(agent)

  step 'Apply Manifest'
  on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(/Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
  end

  step 'Verify Results'
  # PuppetFakeResource always overwrites file at this path
  on(agent, "cat /cygdrive/c/#{test_dir_path}/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
    assert_match(/#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
  end
end
