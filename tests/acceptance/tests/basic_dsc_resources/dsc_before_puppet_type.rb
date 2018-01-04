require 'dsc_utils'
require 'securerandom'

test_name 'FM-2624 - C68527 - Apply DSC Resource Manifest with "before" on Puppet Resource Type'

confine(:to, :platform => 'windows')

# In-line Manifest
test_file_name = SecureRandom.uuid
test_file_path = "C:/#{test_file_name}"
test_file_contents = SecureRandom.uuid
fake_name = SecureRandom.uuid
fake_file_contents = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
file {'#{test_file_path}':
  ensure  => 'file',
  content => '#{test_file_contents}'
}
dsc_puppetfakeresource {'#{fake_name}':
  dsc_ensure          => 'present',
  dsc_importantstuff  => '#{fake_file_contents}',
  before              => File['#{test_file_path}']
}
MANIFEST

# Teardown
teardown do
  step 'Remove Test Artifacts and Type Wrappers'
  on(agents, "rm -rf /cygdrive/c/#{test_file_name}")
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
  on(agent, "cat /cygdrive/c/#{test_file_name}", :acceptable_exit_codes => [0]) do |result|
    assert_match(/#{test_file_contents}/, result.stdout, 'File contents incorrect!')
  end

  # PuppetFakeResource always overwrites file here with "importantstuff"
  on(agent, "cat /cygdrive/c/fakeresource.txt", :acceptable_exit_codes => [0]) do |result|
    assert_match(/#{fake_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
  end
end
