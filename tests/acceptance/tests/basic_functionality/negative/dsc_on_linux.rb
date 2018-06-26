require 'erb'
require 'master_manipulator'
require 'dsc_utils'
require 'securerandom'
test_name 'FM-2623 - C68790 - Attempt to Run DSC Manifest on a Linux Agent'

installed_path = get_dsc_resource_fixture_path(usage = :manifest)

# Manifest
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
dsc { '#{fake_name}':
  resource_name => 'puppetfakeresource',
  module => '#{installed_path}/1.0',
  properties => {
    ensure          => 'present',
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{fake_name}',
  },
}
MANIFEST

# Verify
error_msg = /Could not find a suitable provider for dsc/

# Teardown
teardown do
  step 'Remove Test Artifacts'
  agents.each do |agent|
    teardown_dsc_resource_fixture(agent)
  end
end

# Tests
# NOTE: this test only runs when in a master / agent setup with more than Windows hosts
confine_block(:except, :platform => 'windows') do
  agents.each do |agent|
    step 'Copy Test Type Wrappers'
    setup_dsc_resource_fixture(agent)

    step 'Run Puppet Apply'
    on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => 4) do |result|
      assert_match(error_msg, result.stderr, 'Expected error was not detected!')
    end

    # if this file exists, we're in trouble!
    on(agent, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
  end
end
