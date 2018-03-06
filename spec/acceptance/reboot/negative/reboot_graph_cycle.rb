require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2843 - C96008 - Attempt to Apply DSC Resource that Requires Reboot with Inverse Relationship to a "reboot" Resource'

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
    on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,1]) do |result|
      assert_match(error_message, result.stderr, 'Expected error was not detected!')
    end

    step 'Verify Reboot is NOT Pending'
    expect_failure('Expect that no reboot should be pending.') do
      assert_reboot_pending(agent)
    end
  end
end
