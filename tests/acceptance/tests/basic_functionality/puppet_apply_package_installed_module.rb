require 'erb'
require 'dsc_utils'
require 'securerandom'
test_name 'MODULES-6450 - Add beaker tests for installing DSC Resources via Install-Module cmdlet'

installed_path = get_fake_reboot_resource_install_path(usage = :manifest)

confine(:to, :platform => 'windows')

test_dir_path      = SecureRandom.uuid
fake_name          = SecureRandom.uuid
test_file_contents = SecureRandom.uuid
repo_name          = SecureRandom.uuid
repo_folder        = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
file { 'C:/#{ test_dir_path }' :
   ensure => 'directory'
}
->
dsc { '#{fake_name}':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module => '#{installed_path}/PuppetFakeResource',
  dsc_resource_properties => {
    ensure          => 'present',
    importantstuff  => '#{test_file_contents}',
    destinationpath => '#{"C:\\" + test_dir_path + "\\" + fake_name}',
  },
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
  step 'Create local Nuget repository'
  create_local_nuget_repo(agent, repo_name, repo_folder)

  step 'Publish PuppetFakeResource module to the repo'
  publish_dsc_module_to_nuget(agent, repo_name)
  
  step 'Install the module via Install-Module cmdlet'
  powershell_install_dsc_module(agent, 'puppetfakeresource', repo_name)

  step 'Apply Manifest'
  on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    assert_match(/Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
  end

  step 'Verify Results'
  # PuppetFakeResource always overwrites file at this path
  on(agent, "cat /cygdrive/c/#{test_dir_path}/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
    assert_match(/#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
  end
end
