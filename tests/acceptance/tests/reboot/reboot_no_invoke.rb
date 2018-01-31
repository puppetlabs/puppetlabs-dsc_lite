require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2843 - C96007 - Apply DSC Resource that Does not Require a Reboot with Autonotify "reboot" Resource'

# Manifest
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid
dsc_manifest = <<-MANIFEST
reboot { 'dsc_reboot':
  when => pending
}
dsc_puppetfakeresource { '#{fake_name}':
  dsc_ensure          => present,
  dsc_importantstuff  => '#{test_file_contents}',
  dsc_destinationpath => 'C:\\#{fake_name}'
}
MANIFEST

# Teardown
teardown do
  step 'Remove Test Artifacts'
  agents.each do |agent|
    uninstall_fake_reboot_resource(agent)
  end

  confine_block(:to, :platform => 'windows') do
    step 'Remove Test Artifacts'
    on(agents, "rm -rf /cygdrive/c/#{fake_name}")
  end
end


# Tests
confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    step 'Copy Test Type Wrappers'
    install_fake_reboot_resource(agent)

    # Workaround for https://tickets.puppetlabs.com/browse/IMAGES-539
    step 'Remove PendingFileRenameOperations registry key'
    on(agent, 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /f', :accept_all_exit_codes => true)

    step 'Run Puppet Apply'
    on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
      # NOTE: regex includes Node\[default\]\/ when run via agent rather than apply
      assert_match(/Stage\[main\]\/Main\/Dsc_puppetfakeresource\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_no_match(/Warning:/, result.stderr, 'Unexpected warning was detected!')
    end

    step 'Verify Reboot is NOT Pending'
    expect_failure('Expect that no reboot should be pending.') do
      assert_reboot_pending(agent)
    end
  end
end
