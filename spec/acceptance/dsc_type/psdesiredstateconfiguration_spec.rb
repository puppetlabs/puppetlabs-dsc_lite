# frozen_string_literal: true

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

  let(:dsc_timeout_manifest) do
    <<-MANIFEST
    dsc { "Running Script":
      resource_name => 'Script',
      module        => 'PSDesiredStateConfiguration',
      dsc_timeout   => 1,
      properties    => {
        getscript  => 'Start-Sleep -Seconds 2',
        testscript => '$false',
        setscript  => 'Start-Sleep -Seconds 2',
      },
    }
    MANIFEST
  end

  context 'create a standard DSC File' do
    it 'applies manifest' do
      apply_manifest(dsc_manifest, catch_failures: true) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'creates file' do
      expect(file("C:\\#{fake_name}").content).to match(%r{#{test_file_contents}})
    end
  end

  context 'times out when execution time is greater than dsc_timeout' do
    it 'applies manifest' do
      apply_manifest(dsc_timeout_manifest, expect_failures: true) do |result|
        expect(result.stderr).to match(%r{The DSC Resource did not respond within the timeout limit of 1000 milliseconds})
      end
    end
  end

  context 'remove a standard DSC File' do
    it 'applies manifest' do
      # necessary because the DSC resource may still be running from previous test, so we need to wait for it to finish
      retry_on_error_matching(10, 5, %r{The Invoke-DscResource cmdlet is in progress and must return before Invoke-DscResource can be invoked}) do
        apply_manifest(dsc_remove_manifest, catch_failures: true) do |result|
          expect(result.stderr).not_to match(%r{Error:})
        end
      end
    end

    it 'removes file' do
      expect(file("C:\\#{fake_name}")).not_to exist
    end
  end
end
