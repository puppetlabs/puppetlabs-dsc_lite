require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2843 - C96007 - Apply DSC Resource that Does not Require a Reboot with Autonotify "reboot" Resource'

# Manifest
installed_path = get_fake_reboot_resource_install_path(usage = :manifest)
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid
dsc_manifest = <<-MANIFEST
dsc { '#{fake_name}':
  dsc_resource_name       => 'puppetfakeresource',
  dsc_resource_module     => '#{installed_path}/1.0',
  dsc_resource_properties => {
    ensure          => present,
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{fake_name}',
  }
}
reboot { 'dsc_reboot':
  when => pending
}
MANIFEST

# Teardown
teardown do
  step 'Remove Test Artifacts'
  windows_agents.each do |agent|
    uninstall_fake_reboot_resource(agent)
  end

  step 'Remove Test Artifacts'
  on(windows_agents, "rm -rf /cygdrive/c/#{fake_name}")
end


# Tests
windows_agents.each do |agent|
  step 'Copy Test Type Wrappers'
  install_fake_reboot_resource(agent)

  # Workaround for https://tickets.puppetlabs.com/browse/IMAGES-539
  step 'Remove PendingFileRenameOperations registry key'
  on(agent, 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /f', :accept_all_exit_codes => true)

  step 'Run Puppet Apply'
  on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
    # NOTE: regex includes Node\[default\]\/ when run via agent rather than apply
    assert_match(/Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_no_match(/Warning:/, result.stderr, 'Unexpected warning was detected!')
  end

  step 'Verify Reboot is NOT Pending'
  expect_failure('Expect that no reboot should be pending.') do
    assert_reboot_pending(agent)
  end
end
