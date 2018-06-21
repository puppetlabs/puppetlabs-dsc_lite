require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2843 - C96005 - Apply DSC Resource that Requires Reboot without "reboot" Resource'
pending_test('Implementation of this functionality depends on MODULES-6569')

# Manifest
installed_path = get_dsc_resource_fixture_path(usage = :manifest)
dsc_manifest = <<-MANIFEST
dsc { 'reboot_test':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module => '#{installed_path}/1.0',
  dsc_resource_properties => {
    importantstuff  => 'reboot',
    requirereboot   => true,
  }
}
MANIFEST

# Verify
warning_message = /Warning: No reboot resource found in the graph that has 'dsc_reboot' as its name/

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

  step 'Run Puppet Apply'
  on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
    assert_match(warning_message, result.stderr, 'Expected warning was not detected!')
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify Reboot is NOT Pending'
  expect_failure('Expect that no reboot should be pending.') do
    assert_reboot_pending(agent)
  end
end
