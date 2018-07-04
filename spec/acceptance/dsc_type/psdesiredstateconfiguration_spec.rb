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
    windows_agents.each do |agent|
      it 'Run puppet apply to create file' do
        on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_manifest, :acceptable_exit_codes => [0, 2]) do |result|
          assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
        end
      end

      it 'Verify Results' do
        on(agent, "cat /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [0]) do |result|
          assert_match(/#{test_file_contents}/, result.stdout, 'File contents incorrect!')
        end
      end
    end
  end

  context 'Apply generic DSC Manifest to remove a standard DSC File' do
    windows_agents.each do |agent|
      it 'Applies manifest to remove file' do
        on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_remove_manifest, :acceptable_exit_codes => [0, 2]) do |result|
          assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
        end
      end

      it 'Verify results' do
        # if this file exists, 'absent' didn't work
        on(agent, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
      end
    end
  end
end
