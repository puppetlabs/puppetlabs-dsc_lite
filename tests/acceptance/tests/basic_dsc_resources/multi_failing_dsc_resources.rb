require 'dsc_utils'
require 'securerandom'
test_name 'FM-2624 - C87654 - Apply DSC Resource Manifest with Multiple Failing DSC Resources'

installed_path = get_dsc_resource_fixture_path(usage = :manifest)

# In-line Manifest
throw_message_1 = SecureRandom.uuid
throw_message_2 = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
dsc { 'throw_1':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module => '#{installed_path}/1.0',
  dsc_resource_properties => {
    ensure          => 'present',
    importantstuff  => 'foo',
    throwmessage    => '#{throw_message_1}',
  }
}

dsc { 'throw_2':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module => '#{installed_path}/1.0',
  dsc_resource_properties => {
    ensure          => 'present',
    importantstuff  => 'bar',
    throwmessage    => '#{throw_message_2}',
  }
}
MANIFEST

# Verify
error_msg_1 = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message_1}/
error_msg_2 = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message_2}/

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
    assert_match(error_msg_1, result.stderr, 'Expected error was not detected!')
    assert_match(error_msg_2, result.stderr, 'Expected error was not detected!')
  end
end
