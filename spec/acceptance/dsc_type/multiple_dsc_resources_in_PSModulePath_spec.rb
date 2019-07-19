# rubocop:disable Style/FileName
require 'spec_helper_acceptance'

describe 'multiple versioned resources' do
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

  before(:all) do
    windows_agents.each do |agent|
      setup_dsc_resource_fixture(agent)
      # sourced from different directory
      installed_path = get_dsc_resource_fixture_path(:cygwin)

      # put PuppetFakeResource v1 in $PSHome\Modules
      on(agent, <<-CYGWIN)
        cp --recursive #{installed_path}/1.0 /cygdrive/c/#{pshome_modules_path}/PuppetFakeResource
        # copying from Puppet pluginsync directory includes NULL SID and other wonky perms, so reset
        icacls "C:\\#{pshome_modules_path.tr('/', '\\')}\\PuppetFakeResource\\1.0" /reset /T
      CYGWIN

      # put PuppetFakeResource v2 in $Env:Program Files\WindowsPowerShell\Modules
      # noting that the parent folder *must* be PuppetFakeResource
      on(agent, <<-CYGWIN)
        mkdir -p /cygdrive/c/#{program_files_modules_path}/PuppetFakeResource
        cp --recursive #{installed_path}/2.0 /cygdrive/c/#{program_files_modules_path}/PuppetFakeResource
        # copying from Puppet pluginsync directory includes NULL SID and other wonky perms, so reset
        icacls "C:\\#{program_files_modules_path.delete('\\').tr('/', '\\')}\\PuppetFakeResource\\2.0" /reset /T
      CYGWIN

      # verify DSC shows 2 installed copies of the resource
      check_dsc_resources = 'Get-DscResource PuppetFakeResource | Measure-Object | Select -ExpandProperty Count'
      on(agent, powershell(check_dsc_resources, 'EncodedCommand' => true), acceptable_exit_codes: [0]) do |result|
        assert_match(%r{^2$}, result.stdout, 'Expected 2 copies of PuppetFakeResource to be installed!')
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

  context 'load a DSC resource from PSModulePath by ModuleName when multiple versions exist' do
    context 'when multiple versions exist' do
      # NOTE: regex includes Node\[default\]\/ when run via agent rather than apply
      let(:error_msg) { %r{Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\: Could not evaluate\: Resource PuppetFakeResource was not found\.} }

      it 'applies manifest, raises error' do
        # this scenario fails as DSC doesn't know which version to use
        execute_manifest(dsc_ambiguous_manifest, expect_failures: true) do |result|
          expect(result.stderr).to match(%r{#{error_msg}})
        end
      end

      it 'verifies results' do
        # if this file exists, resource executed
        expect(file("C:\\#{fake_name}")).not_to exist
      end
    end

    context 'when version specified' do
      it 'applies manifest, raises error' do
        execute_manifest(dsc_versioned_manifest, catch_failures: true) do |result|
          expect(result.stderr).not_to match(%r{Error:})
        end
      end

      it 'verifies results' do
        # PuppetFakeResource always overwrites file at this path
        # PuppetFakeResource 2.0 appends "v2" to the written file before "ImportantStuff"
        expect(file("C:\\#{fake_name}")).to be_file
        expect(file("C:\\#{fake_name}").content).to match(%r{^v2#{test_file_contents}})
      end
    end
  end
end
