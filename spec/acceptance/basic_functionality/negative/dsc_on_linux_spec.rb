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

# Verify
  error_msg = /Could not find a suitable provider for dsc/

# NOTE: this test only runs when in a master / agent setup with more than Windows hosts
  context 'Fail to apply dsc_lite manifest on non-windows machine' do
    confine_block(:except, :platform => 'windows') do
      agents.each do |agent|
        it 'Run Puppet Apply' do
          on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => 4) do |result|
            assert_match(error_msg, result.stderr, 'Expected error was not detected!')
          end

          # if this file exists, we're in trouble!
          on(agent, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
        end
      end
    end
  end

  before(:all) do
    agents.each do |agent|
      setup_dsc_resource_fixture(agent)
    end
  end

  after(:all) do
    agents.each do |agent|
      teardown_dsc_resource_fixture(agent)
    end
  end
end
