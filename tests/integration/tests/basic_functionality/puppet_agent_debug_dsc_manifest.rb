require 'erb'
require 'master_manipulator'
require 'dsc_utils'
require 'securerandom'
test_name 'FM-2623 - C68535 - Apply DSC Resource Manifest via "puppet agent" with Debug Enabled'

# ERB Manifest
test_dir_path = SecureRandom.uuid
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
file { 'C:/<%= test_dir_path %>' :
   ensure => 'directory'
}
->
dsc_puppetfakeresource {'<%= fake_name %>':
  dsc_ensure          => 'present',
  dsc_importantstuff  => '<%= test_file_contents %>',
  dsc_destinationpath => '<%= "C:\\" + test_dir_path + "\\" + fake_name %>',
}
MANIFEST

# Verify
debug_msg = /Debug:.*Dsc_puppetfakeresource\[#{fake_name}\]: The container Node\[default\] will propagate my refresh event/

# Teardown
teardown do
  confine_block(:to, :platform => 'windows') do
    step 'Remove Test Artifacts'
    on(agents, "rm -rf /cygdrive/c/#{test_dir_path}")
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
    on(agent, puppet('agent -t --debug --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      assert_match(/Stage\[main\]\/Main\/Node\[default\]\/Dsc_puppetfakeresource\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
      assert_match(debug_msg, result.stdout, 'Expected debug message was not detected!')
    end

    step 'Verify Results'
    # PuppetFakeResource always overwrites file at this path
    on(agent, "cat /cygdrive/c/#{test_dir_path}/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
      assert_match(/#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
    end
  end
end
