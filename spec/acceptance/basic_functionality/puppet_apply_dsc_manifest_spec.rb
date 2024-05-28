# frozen_string_literal: true

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
        module => '#{dsc_resource_fixture_path}/1.0',
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
        module => '#{dsc_resource_fixture_path}/1.0',
        properties => {
          ensure          => 'present',
          importantstuff  => '#{SecureRandom.uuid}',
          destinationpath => '#{'C:\\' + test_dir_path + '\\' + fake_name}',
        },
      }
    MANIFEST
  end

  before(:all) do
    setup_dsc_resource_fixture
  end

  after(:all) do
    run_shell("powershell.exe -NoProfile -Nologo -Command \"Remove-Item -Recurse -Force C:/#{test_dir_path}\"")
    teardown_dsc_resource_fixture
  end

  context 'standard apply' do
    it 'applies manifest' do
      apply_manifest(dsc_manifest, catch_failures: true) do |result|
        expect(result.stderr).not_to match(%r{Error:})
        expect(result.stdout).to match(%r{Stage\[main\]/Main/Dsc\[#{fake_name}\]/ensure: invoked})
      end
    end

    it 'file contains correct contents' do
      expect(file("C:\\#{test_dir_path}\\#{fake_name}")).to be_file
      expect(file("C:\\#{test_dir_path}\\#{fake_name}").content).to match(%r{#{test_file_contents}})
    end
  end

  context 'with "--noop' do
    it 'applies manifest' do
      apply_manifest(dsc_manifest_b, catch_failures: true) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'file does not exist' do
      expect(file("C:\\#{test_dir_path_b}\\#{fake_name_b}")).not_to exist
    end
  end
end
