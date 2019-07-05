require 'spec_helper_acceptance'

describe 'PSDesiredStateConfiguration' do
  fake_name = SecureRandom.uuid
  test_file_contents = SecureRandom.uuid

  let(:dsc_manifest) do
    <<-MANIFEST
      dsc {'#{fake_name}':
        resource_name => 'file',
        module => 'PSDesiredStateConfiguration',
        properties => {
          ensure          => 'present',
          contents  => '#{test_file_contents}',
          destinationpath => 'C:\\#{fake_name}'
        }
      }
    MANIFEST
  end

  let(:dsc_remove_manifest) do
    <<-MANIFEST
      dsc {'#{fake_name}':
        resource_name => 'file',
        module => 'PSDesiredStateConfiguration',
        properties => {
          ensure          => 'absent',
          contents  => '#{test_file_contents}',
          destinationpath => 'C:\\#{fake_name}'
        }
      }
    MANIFEST
  end

  context 'create a standard DSC File' do
    it 'applies manifest' do
      execute_manifest(dsc_manifest, catch_failures: true) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'creates file' do
      expect(file("C:\\#{fake_name}").content).to match(%r{#{test_file_contents}})
    end
  end

  context 'remove a standard DSC File' do
    it 'applies manifest' do
      execute_manifest(dsc_remove_manifest, catch_failures: true) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'removes file' do
      expect(file("C:\\#{fake_name}")).not_to exist
    end
  end
end
