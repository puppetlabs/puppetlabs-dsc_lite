require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2843 - C96006 - Apply DSC Resource that Requires Reboot with Explicit "reboot" Resource'

# Manifest
dsc_manifest = <<-MANIFEST
reboot { 'dsc_reboot':
  when => pending
}
dsc_puppetfakeresource { 'reboot_test':
  dsc_importantstuff => 'reboot',
  dsc_requirereboot => true,
  notify => Reboot['dsc_reboot']
}
MANIFEST

# Teardown
teardown do
  step 'Remove Test Artifacts'
  agents.each do |agent|
    uninstall_fake_reboot_resource(agent)
  end
end

# Tests
confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    step 'Copy Test Type Wrappers'
    install_fake_reboot_resource(agent)

    step 'Run Puppet Apply'
    on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_no_match(/Warning:/, result.stderr, 'Unexpected warning was detected!')
    end

    step 'Verify Reboot is Pending'
    assert_reboot_pending(agent)
  end
end
