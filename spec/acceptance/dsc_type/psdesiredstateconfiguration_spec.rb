require 'spec_helper_acceptance'

describe 'Puppet apply for file resource ensure present and ensure absent' do
  fake_name = SecureRandom.uuid
  test_file_contents = SecureRandom.uuid
  dsc_manifest = <<-MANIFEST
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

  dsc_remove_manifest = <<-MANIFEST
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

  context 'Apply generic DSC Manifest to create a standard DSC File' do
    it 'Run puppet apply to create file' do
      execute_manifest(dsc_manifest, catch_failures: true) do |result|
        assert_no_match(%r{Error:}, result.stderr, 'Unexpected error was detected!')
      end
    end

    it 'Verify Results' do
      on(windows_agents, "cat /cygdrive/c/#{fake_name}", acceptable_exit_codes: [0]) do |result|
        assert_match(%r{#{test_file_contents}}, result.stdout, 'File contents incorrect!')
      end
    end
  end

  context 'Apply generic DSC Manifest to remove a standard DSC File' do
    it 'Applies manifest to remove file' do
      execute_manifest(dsc_remove_manifest, catch_failures: true) do |result|
        assert_no_match(%r{Error:}, result.stderr, 'Unexpected error was detected!')
      end
    end

    it 'Verify results' do
      # if this file exists, 'absent' didn't work
      on(windows_agents, "test -f /cygdrive/c/#{fake_name}", acceptable_exit_codes: [1])
    end
  end
end
