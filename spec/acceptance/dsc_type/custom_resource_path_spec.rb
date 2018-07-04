require 'spec_helper_acceptance'

describe 'Custom resource from path' do

  fake_name = SecureRandom.uuid
  test_file_contents = SecureRandom.uuid
  dsc_manifest = <<-MANIFEST
    dsc {'#{fake_name}':
      resource_name => 'puppetfakeresource',
      # NOTE: install_fake_reboot_resource installs on master, which pluginsyncs here
      module => '#{installed_path}/1.0',
      properties => {
        ensure          => 'present',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{fake_name}'
      }
    }
  MANIFEST

  dsc_remove_manifest = <<-MANIFEST
    dsc {'#{fake_name}':
      resource_name => 'puppetfakeresource',
      module => '#{installed_path}/1.0',
      properties => {
        ensure          => 'absent',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{fake_name}'
      }
    }
  MANIFEST

  context 'Apply generic DSC Manifest to create a puppetfakeresource' do
  windows_agents.each do |agent|
    it 'Run Puppet Apply' do
      on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_manifest, :acceptable_exit_codes => [0, 2]) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    it 'Verify Results' do
      # PuppetFakeResource always overwrites file at this path
      on(agent, "cat /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
        assert_match(/#{test_file_contents}/, result.stdout, 'PuppetFakeResource File contents incorrect!')
      end
    end
  end
  end

  windows_agents.each do |agent|
    it 'Apply Manifest to Remove File' do
      on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_remove_manifest, :acceptable_exit_codes => [0, 2]) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    it 'Verify Results' do
      # if this file exists, 'absent' didn't work
      on(agent, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
    end
  end

  before(:all) do
    windows_agents.each do |agent|
      setup_dsc_resource_fixture(agent)
    end
  end

  after(:all) do
    windows_agents.each do |agent|
      teardown_dsc_resource_fixture(agent)
    end
    on(windows_agents, "rm -rf /cygdrive/c/#{fake_name}")
  end
end
