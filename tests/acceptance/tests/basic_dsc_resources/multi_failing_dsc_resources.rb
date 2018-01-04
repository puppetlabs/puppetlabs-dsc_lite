require 'dsc_utils'
require 'securerandom'
test_name 'FM-2624 - C87654 - Apply DSC Resource Manifest with Multiple Failing DSC Resources'

confine(:to, :platform => 'windows')

# In-line Manifest
throw_message_1 = SecureRandom.uuid
throw_message_2 = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
dsc_puppetfakeresource {'throw_1':
  dsc_ensure          => 'present',
  dsc_importantstuff  => 'foo',
  dsc_throwmessage    => '#{throw_message_1}',
}

dsc_puppetfakeresource {'throw_2':
  dsc_ensure          => 'present',
  dsc_importantstuff  => 'bar',
  dsc_throwmessage    => '#{throw_message_2}',
}
MANIFEST

# Verify
error_msg_1 = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message_1}/
error_msg_2 = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message_2}/

# Teardown
teardown do
  step 'Remove Test Artifacts'
  agents.each do |agent|
    uninstall_fake_reboot_resource(agent)
  end
end

# Tests
agents.each do |agent|
  step 'Copy Test Type Wrappers'
  install_fake_reboot_resource(agent)

  step 'Apply Manifest'
  on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => 0) do |result|
    assert_match(error_msg_1, result.stderr, 'Expected error was not detected!')
    assert_match(error_msg_2, result.stderr, 'Expected error was not detected!')
  end
end
