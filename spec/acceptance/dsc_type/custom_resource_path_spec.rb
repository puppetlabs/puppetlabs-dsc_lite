require 'spec_helper_acceptance'

describe 'custom resource from path' do
  fake_name = SecureRandom.uuid

  test_file_contents = SecureRandom.uuid

  let(:dsc_manifest) do
    <<-MANIFEST
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
  end

  let(:dsc_remove_manifest) do
    <<-MANIFEST
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
  end

  before(:all) do
    windows_agents.each do |agent|
      setup_dsc_resource_fixture(agent)
    end
  end

  after(:all) do
    windows_agents.each do |agent|
      teardown_dsc_resource_fixture(agent)
      on(agent, "rm -rf /cygdrive/c/#{fake_name}")
    end
  end

  context 'create generic DSC resource' do
    it 'applies manifest' do
      execute_manifest(dsc_manifest, catch_failures: true) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'verifies results' do
      # PuppetFakeResource always overwrites file at this path
      expect(file("C:\\#{fake_name}")).to be_file
      expect(file("C:\\#{fake_name}").content).to match(%r{#{test_file_contents}})
    end
  end

  context 'remove generic DSC resource' do
    it 'removes generic DSC resource' do
      on(windows_agents, puppet('apply --detailed-exitcodes'), stdin: dsc_remove_manifest, acceptable_exit_codes: [0, 2]) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'verifies results' do
      expect(file("C:\\#{fake_name}")).not_to exist
    end
  end
end
