require 'erb'
require 'dsc_utils'
require 'securerandom'
test_name 'FM-2623 - C68509 - Apply DSC Resource Manifest in "noop" Mode Using "puppet apply"'

installed_path = get_dsc_resource_fixture_path(usage = :manifest)

# ERB Manifest
test_dir_path = SecureRandom.uuid
fake_name = SecureRandom.uuid

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
    importantstuff  => '#{SecureRandom.uuid}',
    destinationpath => '#{"C:\\" + test_dir_path + "\\" + fake_name}',
  },
}
MANIFEST

# Teardown
teardown do
  windows_agents.each do |agent|
    step 'Remove Test Artifacts'
    teardown_dsc_resource_fixture(agent)
  end
end

# Tests
windows_agents.each do |agent|
  step 'Copy Test Type Wrappers'
  setup_dsc_resource_fixture(agent)

  step 'Apply Manifest'
  on(agent, puppet('apply --noop'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify that No Changes were Made'
  # if this file exists, noop didn't work
  on(agent, "test -f /cygdrive/c/#{test_dir_path}/#{fake_name}", :acceptable_exit_codes => [1])
end
