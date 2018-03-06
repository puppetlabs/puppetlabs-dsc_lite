require 'dsc_utils'
require 'securerandom'
test_name 'FM-2624 - C68533 - Apply DSC Resource Manifest with Mix of Passing and Failing DSC Resources'

confine(:to, :platform => 'windows')

installed_path = get_fake_reboot_resource_install_path(usage = :manifest)

# In-line Manifest
throw_message = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
dsc { 'good_resource':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module => '#{installed_path}/PuppetFakeResource',
  dsc_resource_properties => {
    ensure          => 'present',
    importantstuff  => 'foo',
  }
}

dsc { 'throw_resource':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module => '#{installed_path}/PuppetFakeResource',
  dsc_resource_properties => {
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
    assert_match(error_msg, result.stderr, 'Expected error was not detected!')
  end
end
