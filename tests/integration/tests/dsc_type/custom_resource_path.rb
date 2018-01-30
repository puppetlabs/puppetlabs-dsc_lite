require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'Apply generic DSC Manifest to create a puppetfakeresource'

# Manifest
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid
dsc_manifest = <<-MANIFEST
dsc {'#{fake_name}':
  dsc_resource_name => 'puppetfakeresource',
  # NOTE: install_fake_reboot_resource installs on master, which pluginsyncs here
  dsc_resource_module_name => 'C:/ProgramData/PuppetLabs/puppet/cache/lib/puppet_x/dsc_resources/PuppetFakeResource',
  dsc_resource_properties => {
    ensure          => 'present',
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{fake_name}'
  }
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

    step 'Verify Results'
    # PuppetFakeResource always overwrites file at this path
    on(agent, "cat /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
      assert_match(/#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
    end
  end
end

# New manifest to remove value.
dsc_remove_manifest = <<-MANIFEST
dsc {'#{fake_name}':
  dsc_resource_name => 'puppetfakeresource',
  dsc_resource_module_name => 'C:/ProgramData/PuppetLabs/puppet/cache/lib/puppet_x/dsc_resources/PuppetFakeResource',
  dsc_resource_properties => {
    ensure          => 'absent',
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{fake_name}'
  }
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => dsc_remove_manifest)
inject_site_pp(master, get_site_pp_path(master), site_pp)

confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    step 'Apply Manifest to Remove File'
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step 'Verify Results'
    # if this file exists, 'absent' didn't work
    on(agent, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
  end
end
