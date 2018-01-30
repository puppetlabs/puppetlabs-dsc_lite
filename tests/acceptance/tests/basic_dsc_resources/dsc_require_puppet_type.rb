require 'dsc_utils'
require 'securerandom'

test_name 'FM-2624 - C68526 - Apply DSC Resource Manifest with "requires" on Puppet Resource Type'

confine(:to, :platform => 'windows')

# In-line Manifest
test_dir_path = SecureRandom.uuid
fake_name = SecureRandom.uuid
fake_file_contents = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
dsc_puppetfakeresource {'#{fake_name}':
  dsc_ensure          => 'present',
  dsc_importantstuff  => '#{fake_file_contents}',
  require             => File['C:/#{test_dir_path}']
}
file {'C:/#{test_dir_path}':
  ensure => 'directory'
}
MANIFEST

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
  on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(/Stage\[main\]\/Main\/Dsc_puppetfakeresource\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
  end

  step 'Verify Results'
  on(agent, "test -d \"/cygdrive/c/#{test_dir_path}\"", :acceptable_exit_codes => [0])

  # PuppetFakeResource always overwrites file here with "importantstuff"
  on(agent, "cat /cygdrive/c/fakeresource.txt", :acceptable_exit_codes => [0]) do |result|
    assert_match(/#{fake_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
  end
end
