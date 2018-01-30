require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2965 - C96627 - Apply DSC Manifest with "ensure" Set to "absent" and "dsc_ensure" Set to "present"'

# Manifest
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid
dsc_manifest = <<-MANIFEST
dsc_puppetfakeresource {'#{fake_name}':
  ensure              => 'absent',
  dsc_ensure          => 'present',
  dsc_importantstuff  => '#{test_file_contents}',
  dsc_destinationpath => 'C:\\#{fake_name}'
}
MANIFEST

# Teardown
teardown do
  confine_block(:to, :platform => 'windows') do
    step 'Remove Test Artifacts'
    on(agents, "rm -rf /cygdrive/c/#{fake_name}")
  end

  uninstall_fake_reboot_resource(master)
end

# Setup
step 'Copy Test Type Wrappers'
install_fake_reboot_resource(master)
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => dsc_manifest)
inject_site_pp(master, get_site_pp_path(master), site_pp)

# Tests
confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    step 'Run Puppet Agent'
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step 'Verify that the File is Present. (dsc_ensure takes precedence)'
    # PuppetFakeResource always overwrites file at this path
    on(agent, "cat /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
      assert_match(/#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
    end
  end
end
