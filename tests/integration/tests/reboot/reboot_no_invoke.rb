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
  uninstall_fake_reboot_resource(master)

  confine_block(:to, :platform => 'windows') do
    step 'Remove Test Artifacts'
    on(agents, "rm -rf /cygdrive/c/#{fake_name}")
  end
end

# Setup
install_fake_reboot_resource(master)

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => dsc_manifest)
inject_site_pp(master, get_site_pp_path(master), site_pp)

# Tests
confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    # Workaround for https://tickets.puppetlabs.com/browse/IMAGES-539
    step 'Remove PendingFileRenameOperations registry key'
    on(agent, 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /f', :accept_all_exit_codes => true)

    step 'Run Puppet Agent'
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_match(/Stage\[main\]\/Main\/Node\[default\]\/Dsc_puppetfakeresource\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_no_match(/Warning:/, result.stderr, 'Unexpected warning was detected!')
    end

    step 'Verify Reboot is NOT Pending'
    expect_failure('Expect that no reboot should be pending.') do
      assert_reboot_pending(agent)
    end
  end
end
