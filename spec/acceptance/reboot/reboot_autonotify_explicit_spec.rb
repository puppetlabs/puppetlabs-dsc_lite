require 'spec_helper_acceptance'

describe 'reboot using autonotify, explicit' do
  skip 'Implementation of this functionality depends on MODULES-6569' do
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

    context 'when DSC resource requires reboot with autonotify "reboot" resource' do
      let(:dsc_manifest) do
        <<-MANIFEST
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
      end

      windows_agents.each do |agent|
        it 'applies manifest' do
          on(agent, puppet('apply --detailed-exitcodes'), stdin: dsc_manifest, acceptable_exit_codes: [0, 2]) do |result|
            expect(result.stderr).not_to match(%r{Error:})
            expect(result.stderr).not_to match(%r{Warning:})
          end
        end

        it 'verifies reboot is pending' do
          assert_reboot_pending(agent)
        end
      end
    end

    context 'when DSC Resource requires reboot with explicit "reboot" resource' do
      let(:dsc_manifest) do
        <<-MANIFEST
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
      end

      it 'applies manifest' do
        execute_manifest(dsc_manifest, catch_failures: true) do |result|
          expect(result.stderr).not_to match(%r{Error:})
          expect(result.stderr).not_to match(%r{Warning:})
        end
      end

      it 'verifies reboot is pending' do
        windows_agents.each do |agent|
          assert_reboot_pending(agent)
        end
      end
    end
  end
end
