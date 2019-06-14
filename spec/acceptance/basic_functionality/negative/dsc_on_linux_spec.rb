require 'spec_helper_acceptance'

describe 'FM-2623 - Attempt to Run DSC Manifest on a Linux Agent' do
  fake_name = SecureRandom.uuid
  test_file_contents = SecureRandom.uuid

  dsc_manifest = <<-MANIFEST
    dsc { '#{fake_name}':
      resource_name => 'puppetfakeresource',
      module => '#{installed_path}/1.0',
      properties => {
        ensure          => 'present',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{fake_name}',
      },
    }
  MANIFEST

  error_msg = %r{Could not find a suitable provider for dsc}

  # NOTE: this test only runs when in a master / agent setup with more than Windows hosts
  context 'Fail to apply dsc_lite manifest on non-windows machine' do
    confine_block(:except, platform: 'windows') do
      agents.each do |agent|
        it 'Run Puppet Apply' do
          execute_manifest(dsc_manifest, expect_failures: true) do |result|
            assert_match(error_msg, result.stderr, 'Expected error was not detected!')
            assert_match(result.exit_code, 4)
          end

          # if this file exists, we're in trouble!
          on(agent, "test -f /cygdrive/c/#{fake_name}", acceptable_exit_codes: [1])
        end
      end
    end
  end
end
