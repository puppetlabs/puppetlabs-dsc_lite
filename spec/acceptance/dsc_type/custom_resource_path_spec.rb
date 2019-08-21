require 'spec_helper_acceptance'

describe 'custom resource from path' do
  fake_name = SecureRandom.uuid

  test_file_contents = SecureRandom.uuid

  let(:dsc_manifest) do
    <<-MANIFEST
      dsc {'#{fake_name}':
        resource_name => 'puppetfakeresource',
        # NOTE: install_fake_reboot_resource installs on master, which pluginsyncs here
        module => '#{dsc_resource_fixture_path}/1.0',
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
        module => '#{dsc_resource_fixture_path}/1.0',
        properties => {
          ensure          => 'absent',
          importantstuff  => '#{test_file_contents}',
          destinationpath => 'C:\\#{fake_name}'
        }
      }
    MANIFEST
  end

  before(:all) do
    setup_dsc_resource_fixture
  end

  after(:all) do
    teardown_dsc_resource_fixture
    run_shell("powershell.exe -NoProfile -Nologo -Command \"Remove-Item -Recurse -Force 'C:/#{fake_name}'\"", expect_failures: true)
  end

  context 'create generic DSC resource' do
    it 'applies manifest' do
      apply_manifest(dsc_manifest, catch_failures: true) do |result|
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
      apply_manifest(dsc_remove_manifest, catch_failures: true) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'verifies results' do
      expect(file("C:\\#{fake_name}")).not_to exist
    end
  end
end
