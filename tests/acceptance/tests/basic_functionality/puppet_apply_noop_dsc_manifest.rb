require 'erb'
require 'dsc_utils'
require 'securerandom'
test_name 'FM-2623 - C68509 - Apply DSC Resource Manifest in "noop" Mode Using "puppet apply"'

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

# Teardown
teardown do
  agents.each do |agent|
    step 'Remove Test Artifacts'
    uninstall_fake_reboot_resource(agent)
  end
end

# Tests
agents.each do |agent|
  step 'Copy Test Type Wrappers'
  install_fake_reboot_resource(agent)

  step 'Apply Manifest'
  on(agent, puppet('apply --noop'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify that No Changes were Made'
  # if this file exists, noop didn't work
  on(agent, "test -f /cygdrive/c/#{test_dir_path}/#{fake_name}", :acceptable_exit_codes => [1])
end
