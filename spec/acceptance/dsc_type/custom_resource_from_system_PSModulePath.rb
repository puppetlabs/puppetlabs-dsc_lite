require 'erb'
require 'master_manipulator'
require 'dsc_utils'
# this scenario works properly with only a single PuppetFakeResource in module path
test_name 'Loads a custom DSC resource from system PSModulePath by ModuleName'

# DSC runs in system context / can't use users module path
pshome_modules_path = 'Windows/system32/WindowsPowerShell/v1.0/Modules'

# Manifest
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid
dsc_manifest = <<-MANIFEST
dsc {'#{fake_name}':
  dsc_resource_name => 'PuppetFakeResource',
  # NOTE: relies on finding resource in system part of $ENV:PSModulePath
  dsc_resource_module => 'PuppetFakeResource',
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
    agents.each do |agent|
      uninstall_fake_reboot_resource(agent)
    end
    on(agents, <<-CYGWIN)
rm -rf /cygdrive/c/#{pshome_modules_path}/PuppetFakeResource
rm -rf /cygdrive/c/#{fake_name}
CYGWIN
  end
end

confine_block(:to, :platform => 'windows') do
  step 'Copy Test Type Wrappers'
  install_fake_reboot_resource(agent)

  step 'Copy PuppetFakeResource implementation to system PSModulePath'
  installed_path = get_fake_reboot_resource_install_path(usage = :cygwin)

  # put PuppetFakeResource in $PSHome\Modules
  on(agents, <<-CYGWIN)
cp --recursive #{installed_path}/PuppetFakeResource /cygdrive/c/#{pshome_modules_path}
# copying from Puppet pluginsync directory includes NULL SID and other wonky perms, so reset
icacls "C:\\#{pshome_modules_path.gsub('/', '\\')}\\PuppetFakeResource" /reset /T
CYGWIN
end

# Tests
confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    step 'Run Puppet Apply'
    on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step 'Verify Results'
    # PuppetFakeResource always overwrites file at this path
    on(agent, "cat /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
      assert_match(/^#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
    end
  end
end
