require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2843 - C96008 - Attempt to Apply DSC Resource that Requires Reboot with Inverse Relationship to a "reboot" Resource'
pending_test('Implementation of this functionality depends on MODULES-6569')

# Manifest
dsc_manifest = <<-MANIFEST
reboot { 'dsc_reboot':
  when => pending,
  notify => Dsc_puppetfakeresource['reboot_test']
}
dsc_puppetfakeresource { 'reboot_test':
  dsc_importantstuff => 'reboot',
  dsc_requirereboot => true,
}
MANIFEST

# Verify
error_message = /Error:.*Found 1 dependency cycle/

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
  on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,1]) do |result|
    assert_match(error_message, result.stderr, 'Expected error was not detected!')
  end

  step 'Verify Reboot is NOT Pending'
  expect_failure('Expect that no reboot should be pending.') do
    assert_reboot_pending(agent)
  end
end
