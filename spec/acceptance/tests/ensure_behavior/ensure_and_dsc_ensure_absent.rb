require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'MODULES-2965 - C96629 - Apply DSC Manifest with "ensure" and "dsc_ensure" Set to "absent"'

# Manifest
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid
dsc_manifest = <<-MANIFEST
dsc_puppetfakeresource {'#{fake_name}':
  dsc_ensure          => 'present',
  dsc_importantstuff  => '#{test_file_contents}',
  dsc_destinationpath => 'C:\\#{fake_name}'
}
MANIFEST

# Teardown
teardown do
  confine_block(:to, :platform => 'windows') do
    agents.each do |agent|
      uninstall_fake_reboot_resource(agent)
    end

    step 'Remove Test Artifacts'
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
dsc_puppetfakeresource {'#{fake_name}':
  ensure              => 'absent',
  dsc_ensure          => 'absent',
  dsc_importantstuff  => '#{test_file_contents}',
  dsc_destinationpath => 'C:\\#{fake_name}'
}
MANIFEST

confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    step 'Apply Manifest to Remove File'
    on(agent, puppet('apply'), :stdin => dsc_remove_manifest, :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step 'Verify Results'
    # if this file exists, 'absent' didn't work
    on(agent, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
  end
end
