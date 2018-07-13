require 'spec_helper_acceptance'

describe 'Multiple versioned resource tests' do

  # DSC runs in system context / cannot use users module path
  pshome_modules_path = 'Windows/system32/WindowsPowerShell/v1.0/Modules'
  program_files_modules_path = 'Program\ Files/WindowsPowerShell/Modules'

  fake_name = SecureRandom.uuid

  # Ambiguous resource reference
  test_file_contents = SecureRandom.uuid
  dsc_ambiguous_manifest = <<-MANIFEST
    dsc {'#{fake_name}':
      resource_name => 'PuppetFakeResource',
      # NOTE: relies on finding resource in system parts of $ENV:PSModulePath
      module => 'PuppetFakeResource',
      properties => {
        ensure          => 'present',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{fake_name}'
      }
    }
  MANIFEST

  # Versioned reference
  dsc_versioned_manifest = <<-MANIFEST
    dsc {'#{fake_name}':
      resource_name => 'PuppetFakeResource',
      # NOTE: relies on finding resource in system parts of $ENV:PSModulePath
      module => {
        name    => 'PuppetFakeResource',
        version => '2.0',
      },
      properties => {
        ensure          => 'present',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{fake_name}'
      }
    }
  MANIFEST

  context 'Cannot load a DSC resource from PSModulePath by ModuleName when multiple versions exist' do
    it 'Run Puppet Apply' do
      # this scenario fails as DSC doesn't know which version to use
      execute_manifest(dsc_ambiguous_manifest, :expect_failures => true) do |result|
        # NOTE: regex includes Node\[default\]\/ when run via agent rather than apply
        error_msg = /Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\: Could not evaluate\: Resource PuppetFakeResource was not found\./
        assert_match(error_msg, result.stderr, 'Expected Invoke-DscResource error missing!')
      end
    end

    it 'Verify that the File is Absent.' do
      # if this file exists, resource executed
      on(windows_agents, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
    end
  end

  context 'Can load DSC Resource from PSModulePath by ModuleName when version specified' do
    it 'Run Puppet Apply' do
      execute_manifest(dsc_versioned_manifest, :catch_failures => true) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    it 'Verify Results' do
      # PuppetFakeResource always overwrites file at this path
      # PuppetFakeResource 2.0 appends "v2" to the written file before "ImportantStuff"
      on(windows_agents, "cat /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
        assert_match(/^v2#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
      end
    end
  end

  before(:all) do
    windows_agents.each do |agent|
      setup_dsc_resource_fixture(agent)
      # sourced from different directory
      installed_path = get_dsc_resource_fixture_path(usage = :cygwin)

      # put PuppetFakeResource v1 in $PSHome\Modules
      on(agent, <<-CYGWIN)
        cp --recursive #{installed_path}/1.0 /cygdrive/c/#{pshome_modules_path}/PuppetFakeResource
        # copying from Puppet pluginsync directory includes NULL SID and other wonky perms, so reset
        icacls "C:\\#{pshome_modules_path.gsub('/', '\\')}\\PuppetFakeResource\\1.0" /reset /T
      CYGWIN

      # put PuppetFakeResource v2 in $Env:Program Files\WindowsPowerShell\Modules
      # noting that the parent folder *must* be PuppetFakeResource
      on(agent, <<-CYGWIN)
        mkdir -p /cygdrive/c/#{program_files_modules_path}/PuppetFakeResource
        cp --recursive #{installed_path}/2.0 /cygdrive/c/#{program_files_modules_path}/PuppetFakeResource
        # copying from Puppet pluginsync directory includes NULL SID and other wonky perms, so reset
        icacls "C:\\#{program_files_modules_path.gsub('\\', '').gsub('/', '\\')}\\PuppetFakeResource\\2.0" /reset /T
      CYGWIN

      # verify DSC shows 2 installed copies of the resource
      check_dsc_resources = 'Get-DscResource PuppetFakeResource | Measure-Object | Select -ExpandProperty Count'
      on(agent, powershell(check_dsc_resources, {'EncodedCommand' => true}), :acceptable_exit_codes => [0]) do |result|
        assert_match(/^2$/, result.stdout, 'Expected 2 copies of PuppetFakeResource to be installed!')
      end
    end
  end

  after(:all) do
    windows_agents.each do |agent|
      teardown_dsc_resource_fixture(agent)

      on(agent, <<-CYGWIN)
        rm -rf /cygdrive/c/#{pshome_modules_path}/PuppetFakeResource/1.0
        rm -rf /cygdrive/c/#{program_files_modules_path}/PuppetFakeResource/2.0
        rm -rf /cygdrive/c/#{fake_name}
      CYGWIN
    end
  end
end
