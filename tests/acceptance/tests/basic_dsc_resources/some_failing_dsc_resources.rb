require 'dsc_utils'
require 'securerandom'
test_name 'FM-2624 - C68533 - Apply DSC Resource Manifest with Mix of Passing and Failing DSC Resources'

installed_path = get_dsc_resource_fixture_path(usage = :manifest)

# In-line Manifest
throw_message = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
dsc { 'good_resource':
  resource_name => 'puppetfakeresource',
  module => '#{installed_path}/1.0',
  properties => {
    ensure          => 'present',
    importantstuff  => 'foo',
  }
}

dsc { 'throw_resource':
  resource_name => 'puppetfakeresource',
  module => '#{installed_path}/1.0',
  properties => {
    ensure          => 'present',
    importantstuff  => 'bar',
    throwmessage    => '#{throw_message}',
  }
}
MANIFEST

# Verify
error_msg = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message}/

# Teardown
teardown do
  step 'Remove Test Artifacts'
  windows_agents.each do |agent|
    teardown_dsc_resource_fixture(agent)
  end
end

# Tests
windows_agents.each do |agent|
  step 'Copy Test Type Wrappers'
  setup_dsc_resource_fixture(agent)
  step 'Apply Manifest'
  on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => 0) do |result|
    assert_match(error_msg, result.stderr, 'Expected error was not detected!')
  end
end
