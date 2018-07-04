require 'spec_helper_acceptance'

# this scenario works properly with only a single PuppetFakeResource in module path
describe 'Custom resource from system path' do

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

  context 'Loads a custom DSC resource from system PSModulePath by ModuleName' do
    windows_agents.each do |agent|
      it 'Run Puppet Apply' do
        on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_manifest, :acceptable_exit_codes => [0, 2]) do |result|
          assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
        end
      end

      it 'Verify Results' do
        # PuppetFakeResource always overwrites file at this path
        on(agent, "cat /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
          assert_match(/^#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
        end
      end
    end
  end

  before(:all) do
    windows_agents.each do |agent|
      setup_dsc_resource_fixture(agent)

      installed_path = get_dsc_resource_fixture_path(usage = :cygwin)

      # put PuppetFakeResource in $PSHome\Modules
      # Copy PuppetFakeResource implementation to system PSModulePath
      on(agent, <<-CYGWIN)
        cp --recursive #{installed_path}/1.0 /cygdrive/c/#{pshome_modules_path}/PuppetFakeResource
        # copying from Puppet pluginsync directory includes NULL SID and other wonky perms, so reset
        icacls "C:\\#{pshome_modules_path.gsub('/', '\\')}\\PuppetFakeResource\\1.0" /reset /T
      CYGWIN
    end
  end

  after(:all) do
    windows_agents.each do |agent|
      teardown_dsc_resource_fixture(agent)
      on(windows_agents, <<-CYGWIN)
        rm -rf /cygdrive/c/#{pshome_modules_path}/PuppetFakeResource/1.0
        rm -rf /cygdrive/c/#{fake_name}
      CYGWIN
    end
  end
end

