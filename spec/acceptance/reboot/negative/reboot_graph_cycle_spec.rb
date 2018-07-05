require 'spec_helper_acceptance'

describe 'Reboot - Negative Tests' do

  dsc_manifest = <<-MANIFEST
    reboot { 'dsc_reboot':
      when => pending,
      notify => Dsc_puppetfakeresource['reboot_test']
    }
    dsc_puppetfakeresource { 'reboot_test':
      dsc_importantstuff => 'reboot',
      dsc_requirereboot => true,
    }
  MANIFEST

  error_message = /Error:.*Found 1 dependency cycle/
  skip 'Implementation of this functionality depends on MODULES-6569' do
    context 'MODULES-2843 - Attempt to Apply DSC Resource that Requires Reboot with Inverse Relationship to a "reboot" Resource' do
      windows_agents.each do |agent|
        it 'Run Puppet Apply' do
          on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_manifest, :acceptable_exit_codes => [0, 1]) do |result|
            assert_match(error_message, result.stderr, 'Expected error was not detected!')
          end
        end

        it 'Verify Reboot is NOT Pending' do
          expect_failure('Expect that no reboot should be pending.') do
            assert_reboot_pending(agent)
          end
        end
      end
    end
  end

  before(:all) do
    windows_agents.each do |agent|
      setup_dsc_resource_fixture(agent)
    end
  end

  after(:all) do
    windows_agents.each do |agent|
      teardown_dsc_resource_fixture(agent)
    end
  end
end
