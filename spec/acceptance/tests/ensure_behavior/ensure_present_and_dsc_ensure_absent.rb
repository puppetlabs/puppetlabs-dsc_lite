require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2965 - C96626 - Apply DSC Manifest with "ensure" Set to "present" and "dsc_ensure" Set to "absent"'

installed_path = get_fake_reboot_resource_install_path(usage = :manifest)

# Manifest
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid
dsc_manifest = <<-MANIFEST
dsc { '#{fake_name}':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module => '#{installed_path}/PuppetFakeResource',
  dsc_resource_properties => {
    ensure          => 'present',
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{fake_name}',
  },
}
MANIFEST

# Teardown
teardown do
  confine_block(:to, :platform => 'windows') do
    step 'Remove Test Artifacts'
    agents.each do |agent|
      uninstall_fake_reboot_resource(agent)
    end

    on(agents, "rm -rf /cygdrive/c/#{fake_name}")
  end
end

# Tests
confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    step 'Copy Test Type Wrappers'
    install_fake_reboot_resource(agent)

    step 'Apply Manifest to Create File'
    on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end
  end
end

# New manifest to remove value.
dsc_remove_manifest = <<-MANIFEST
dsc { '#{fake_name}':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module => '#{installed_path}/PuppetFakeResource',
  dsc_resource_properties => {
    ensure          => 'absent',
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{fake_name}',
  },
  ensure => 'present',
}
MANIFEST

confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    step 'Apply Manifest to Remove File'
    on(agent, puppet('apply'), :stdin => dsc_remove_manifest, :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step 'Verify that the File is Absent. (dsc_ensure takes precedence)'
    # if this file exists, dsc_ensure precedent for 'absent' didn't work
    on(agent, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
  end
end
