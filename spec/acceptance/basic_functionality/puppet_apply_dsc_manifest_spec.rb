require 'spec_helper_acceptance'

describe 'puppet apply' do
  test_dir_path = SecureRandom.uuid
  fake_name = SecureRandom.uuid
  test_file_contents = SecureRandom.uuid
  test_dir_path_b = SecureRandom.uuid
  fake_name_b = SecureRandom.uuid

  let(:dsc_manifest) do
    <<-MANIFEST
      file { 'C:/#{test_dir_path}' :
          ensure => 'directory'
      }
      ->
      dsc { '#{fake_name}':
        resource_name => 'puppetfakeresource',
        module => '#{installed_path}/1.0',
        properties => {
          ensure          => 'present',
          importantstuff  => '#{test_file_contents}',
          destinationpath => '#{'C:\\' + test_dir_path + '\\' + fake_name}',
        },
      }
    MANIFEST
  end

  let(:dsc_manifest_b) do
    <<-MANIFEST
      file { 'C:/#{test_dir_path}' :
          ensure => 'directory'
      }
      ->
      dsc { '#{fake_name_b}':
        resource_name => 'puppetfakeresource',
        module => '#{installed_path}/1.0',
        properties => {
          ensure          => 'present',
          importantstuff  => '#{SecureRandom.uuid}',
          destinationpath => '#{'C:\\' + test_dir_path + '\\' + fake_name}',
        },
      }
    MANIFEST
  end

  before(:all) do
    windows_agents.each do |agent|
      setup_dsc_resource_fixture(agent)
    end
  end

  after(:all) do
    on(windows_agents, "rm -rf /cygdrive/c/#{test_dir_path}")
    windows_agents.each do |agent|
      teardown_dsc_resource_fixture(agent)
    end
  end

  context 'standard apply' do
    it 'applies manifest' do
      execute_manifest(dsc_manifest, catch_failures: true) do |result|
        expect(result.stderr).not_to match(%r{Error:})
        expect(result.stdout).to match(%r{Stage\[main\]\/Main\/Dsc\[#{fake_name}\]/ensure\: invoked})
      end
    end

    it 'file contains correct contents' do
      expect(file("C:\\#{test_dir_path}\\#{fake_name}")).to be_file
      expect(file("C:\\#{test_dir_path}\\#{fake_name}").content).to match(%r{#{test_file_contents}})
    end
  end

  context 'with "--noop' do
    it 'applies manifest' do
      on(windows_agents, puppet('apply --noop --detailed-exitcodes'), stdin: dsc_manifest_b, acceptable_exit_codes: [0, 2]) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'file does not exist' do
      expect(file("C:\\#{test_dir_path_b}\\#{fake_name_b}")).not_to exist
    end
  end
end
