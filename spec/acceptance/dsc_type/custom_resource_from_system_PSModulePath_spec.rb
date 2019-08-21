# rubocop:disable Style/FileName
require 'spec_helper_acceptance'

# this scenario works properly with only a single PuppetFakeResource in module path
describe 'custom resource from system path' do
  # DSC runs in system context / can't use users module path
  pshome_modules_path = 'Windows/system32/WindowsPowerShell/v1.0/Modules'

  fake_name = SecureRandom.uuid
  test_file_contents = SecureRandom.uuid
  dsc_manifest = <<-MANIFEST
    dsc {'#{fake_name}':
      resource_name => 'PuppetFakeResource',
      # NOTE: relies on finding resource in system part of $ENV:PSModulePath
      module => 'PuppetFakeResource',
      properties => {
        ensure          => 'present',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{fake_name}'
      }
    }
  MANIFEST

  before(:all) do
    teardown_dsc_resource_fixture
    setup_dsc_resource_fixture

    # put PuppetFakeResource in $PSHome\Modules
    # Copy PuppetFakeResource implementation to system PSModulePath
    run_shell("powershell.exe -NoProfile -Nologo -Command \"Copy-Item '#{dsc_resource_fixture_path}/1.0' 'C:/#{pshome_modules_path}/PuppetFakeResource' -Recurse -Force\"")
    # copying from Puppet pluginsync directory includes NULL SID and other wonky perms, so reset
    run_shell("icacls \"C:\\#{pshome_modules_path.tr('/', '\\')}\\PuppetFakeResource\\1.0\" /reset /T")
  end

  after(:all) do
    teardown_dsc_resource_fixture
    run_shell("powershell.exe -NoProfile -Nologo -Command \"Remove-Item -Recurse -Path 'C:/#{fake_name}'\"")
  end

  context 'load custom DSC resource from system PSModulePath by ModuleName' do
    it 'applies manifest' do
      apply_manifest(dsc_manifest, catch_failures: true) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'verifies results' do
      # PuppetFakeResource always overwrites file at this path
      expect(file("C:\\#{fake_name}")).to be_file
      expect(file("C:\\#{fake_name}").content).to match(%r{^#{test_file_contents}})
    end
  end
end
