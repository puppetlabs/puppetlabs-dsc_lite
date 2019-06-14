require 'spec_helper_acceptance'

describe 'Reboot tests: Autonotify, Explicit' do
  skip 'Implementation of this functionality depends on MODULES-6569' do
    context 'MODULES-2843 - Apply DSC Resource that Requires Reboot with Autonotify "reboot" Resource' do
      dsc_manifest = <<-MANIFEST
    dsc { 'reboot_test':
      resource_name => 'puppetfakeresource',
      module => '#{installed_path}/1.0',
      properties => {
        importantstuff  => 'reboot',
        requirereboot   => true,
      }
    }
    reboot { 'dsc_reboot':
      when => pending
    }
      MANIFEST

      windows_agents.each do |agent|
        it 'Run Puppet Apply' do
          on(agent, puppet('apply --detailed-exitcodes'), stdin: dsc_manifest, acceptable_exit_codes: [0, 2]) do |result|
            assert_no_match(%r{Error:}, result.stderr, 'Unexpected error was detected!')
            assert_no_match(%r{Warning:}, result.stderr, 'Unexpected warning was detected!')
          end
        end

        it 'Verify Reboot is Pending' do
          assert_reboot_pending(agent)
        end
      end
    end

    context 'MODULES-2843 - Apply DSC Resource that Requires Reboot with Explicit "reboot" Resource' do
      dsc_manifest = <<-MANIFEST
      dsc { 'reboot_test':
        dsc_resource_name       => 'puppetfakeresource',
        dsc_resource_module     => '#{installed_path}/1.0',
        dsc_resource_properties => {
          importantstuff => 'reboot',
          requirereboot  => true,
        },
        notify                  => Reboot['dsc_reboot'],
      }
      reboot { 'dsc_reboot':
        when => pending
      }
      MANIFEST

      it 'Run Puppet Apply' do
        execute_manifest(dsc_manifest, catch_failures: true) do |result|
          assert_no_match(%r{Error:}, result.stderr, 'Unexpected error was detected!')
          assert_no_match(%r{Warning:}, result.stderr, 'Unexpected warning was detected!')
        end
      end

      it 'Verify Reboot is Pending' do
        windows_agents.each do |agent|
          assert_reboot_pending(agent)
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
