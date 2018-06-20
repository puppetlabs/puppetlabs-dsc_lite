require 'erb'
require 'master_manipulator'
require 'dsc_utils'
test_name 'Cannot load a DSC resource from PSModulePath by ModuleName when multiple versions exist'

# DSC runs in system context / cannot use users module path
pshome_modules_path = 'Windows/system32/WindowsPowerShell/v1.0/Modules'
program_files_modules_path = 'Program\ Files/WindowsPowerShell/Modules'

# Manifest
fake_name = SecureRandom.uuid

# Teardown
teardown do
  step 'Remove Test Artifacts'
  windows_agents.each do |agent|
    teardown_dsc_resource_fixture(agent)
  end

  on(windows_agents, <<-CYGWIN)
rm -rf /cygdrive/c/#{pshome_modules_path}/PuppetFakeResource/1.0
rm -rf /cygdrive/c/#{program_files_modules_path}/PuppetFakeResource/2.0
rm -rf /cygdrive/c/#{fake_name}
CYGWIN
end

step 'Copy Test Type Wrappers'
setup_dsc_resource_fixture(agent)

step 'Copy PuppetFakeResource implementations to system PSModulePath locations'
# sourced from different directory
installed_path = get_dsc_resource_fixture_path(usage = :cygwin)

# put PuppetFakeResource v1 in $PSHome\Modules
on(windows_agents, <<-CYGWIN)
cp --recursive #{installed_path}/1.0 /cygdrive/c/#{pshome_modules_path}/PuppetFakeResource
# copying from Puppet pluginsync directory includes NULL SID and other wonky perms, so reset
icacls "C:\\#{pshome_modules_path.gsub('/', '\\')}\\PuppetFakeResource\\1.0" /reset /T
CYGWIN

# put PuppetFakeResource v2 in $Env:Program Files\WindowsPowerShell\Modules
# noting that the parent folder *must* be PuppetFakeResource
on(windows_agents, <<-CYGWIN)
mkdir -p /cygdrive/c/#{program_files_modules_path}/PuppetFakeResource
cp --recursive #{installed_path}/2.0 /cygdrive/c/#{program_files_modules_path}/PuppetFakeResource
# copying from Puppet pluginsync directory includes NULL SID and other wonky perms, so reset
icacls "C:\\#{program_files_modules_path.gsub('\\', '').gsub('/', '\\')}\\PuppetFakeResource\\2.0" /reset /T
CYGWIN

# verify DSC shows 2 installed copies of the resource
check_dsc_resources = 'Get-DscResource PuppetFakeResource | Measure-Object | Select -ExpandProperty Count'
on(windows_agents, powershell(check_dsc_resources, {'EncodedCommand' => true}), :acceptable_exit_codes => [0]) do |result|
  assert_match(/^2$/, result.stdout, 'Expected 2 copies of PuppetFakeResource to be installed!')
end

# Test that DSC won't resolve ambiguous resource reference
test_file_contents = SecureRandom.uuid
dsc_ambiguous_manifest = <<-MANIFEST
dsc {'#{fake_name}':
  dsc_resource_name => 'PuppetFakeResource',
  # NOTE: relies on finding resource in system parts of $ENV:PSModulePath
  dsc_resource_module => 'PuppetFakeResource',
  dsc_resource_properties => {
    ensure          => 'present',
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{fake_name}'
  }
}
MANIFEST

windows_agents.each do |agent|
  step 'Run Puppet Apply'

  # this scenario fails as DSC doesn't know which version to use
  on(agent, puppet('apply'), :stdin => dsc_ambiguous_manifest, :acceptable_exit_codes => [0,2,4]) do |result|
    # NOTE: regex includes Node\[default\]\/ when run via agent rather than apply
    error_msg = /Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\: Could not evaluate\: Resource PuppetFakeResource was not found\./
    assert_match(error_msg, result.stderr, 'Expected Invoke-DscResource error missing!')
  end

  step 'Verify that the File is Absent.'
  # if this file exists, resource executed
  on(agent, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
end

# Test that DSC works with versioned reference
dsc_versioned_manifest = <<-MANIFEST
dsc {'#{fake_name}':
  dsc_resource_name => 'PuppetFakeResource',
  # NOTE: relies on finding resource in system parts of $ENV:PSModulePath
  dsc_resource_module => {
    name    => 'PuppetFakeResource',
    version => '2.0',
  },
  dsc_resource_properties => {
    ensure          => 'present',
    importantstuff  => '#{test_file_contents}',
    destinationpath => 'C:\\#{fake_name}'
  }
}
MANIFEST

# Tests
windows_agents.each do |agent|
  step 'Run Puppet Apply'
  on(agent, puppet('apply'), :stdin => dsc_versioned_manifest, :acceptable_exit_codes => [0]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step 'Verify Results'
  # PuppetFakeResource always overwrites file at this path
  # PuppetFakeResource 2.0 appends "v2" to the written file before "ImportantStuff"
  on(agent, "cat /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
    assert_match(/^v2#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
  end
end
