require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2843 - C96005 - Apply DSC Resource that Requires Reboot without "reboot" Resource'

# Manifest
installed_path = get_fake_reboot_resource_install_path(usage = :manifest)
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
    uninstall_fake_reboot_resource(agent)
  end
end

# Tests
windows_agents.each do |agent|
  step 'Copy Test Type Wrappers'
  install_fake_reboot_resource(agent)

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
