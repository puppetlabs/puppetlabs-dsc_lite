require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2843 - C96006 - Apply DSC Resource that Requires Reboot with Explicit "reboot" Resource'

# Manifest
installed_path = get_dsc_resource_fixture_path(usage = :manifest)
dsc_manifest = <<-MANIFEST
dsc { 'reboot_test':
  dsc_resource_name       => 'puppetfakeresource',
  dsc_resource_module     => '#{installed_path}/1.0',
  dsc_resource_properties => {
    importantstuff => 'reboot',
    requirereboot  => true,
  },
  notify                  => Reboot['dsc_reboot'],
}
reboot { 'dsc_reboot':
  when => pending
}
MANIFEST

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
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_no_match(/Warning:/, result.stderr, 'Unexpected warning was detected!')
  end

  step 'Verify Reboot is Pending'
  assert_reboot_pending(agent)
end
