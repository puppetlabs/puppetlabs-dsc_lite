require 'erb'
require 'dsc_utils'
require 'securerandom'
test_name 'FM-2623 - C68534 - Apply DSC Resource Manifest via "puppet apply" with Debug Enabled'

confine(:to, :platform => 'windows')

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
  dsc_destinationpath => '<%= defined?(test_file_path) ? test_file_path : "C:\\" + test_dir_path + "\\" + fake_name %>',
}
MANIFEST

# Verify
debug_msg = /Debug:.*Dsc_puppetfakeresource\[#{fake_name}\]: The container Class\[Main\] will propagate my refresh event/

# Teardown
teardown do
  step 'Remove Test Artifacts'
  on(agents, "rm -rf /cygdrive/c/#{test_dir_path}")
  agents.each do |agent|
    uninstall_fake_reboot_resource(agent)
  end
end

# Tests
agents.each do |agent|
  step 'Copy Test Type Wrappers'
  install_fake_reboot_resource(agent)

  step 'Apply Manifest'
  on(agent, puppet('apply --debug'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(/Stage\[main\]\/Main\/Dsc_puppetfakeresource\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
    assert_match(debug_msg, result.stdout, 'Expected debug message was not detected!')
  end

  step 'Verify Results'
  # PuppetFakeResource always overwrites file at this path
  on(agent, "cat /cygdrive/c/#{test_dir_path}/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
    assert_match(/#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
  end
end
