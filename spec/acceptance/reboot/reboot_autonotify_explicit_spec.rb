# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'reboot using autonotify, explicit' do
  skip 'Implementation of this functionality depends on MODULES-6569' do
    before(:all) do
      setup_dsc_resource_fixture
    end

    after(:all) do
      teardown_dsc_resource_fixture
    end

    context 'when DSC resource requires reboot with autonotify "reboot" resource' do
      let(:dsc_manifest) do
        <<-MANIFEST
          dsc { 'reboot_test':
            resource_name => 'puppetfakeresource',
            module => '#{dsc_resource_fixture_path}/1.0',
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

      it 'applies manifest' do
        run_shell(puppet('apply --detailed-exitcodes'), stdin: dsc_manifest, acceptable_exit_codes: [0, 2]) do |result|
          expect(result.stderr).not_to match(%r{Error:})
          expect(result.stderr).not_to match(%r{Warning:})
        end
      end

      it 'verifies reboot is pending' do
        assert_reboot_pending(agent)
      end
    end

    context 'when DSC Resource requires reboot with explicit "reboot" resource' do
      let(:dsc_manifest) do
        <<-MANIFEST
          dsc { 'reboot_test':
            dsc_resource_name       => 'puppetfakeresource',
            dsc_resource_module     => '#{dsc_resource_fixture_path}/1.0',
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
        apply_manifest(dsc_manifest, catch_failures: true) do |result|
          expect(result.stderr).not_to match(%r{Error:})
          expect(result.stderr).not_to match(%r{Warning:})
        end
      end

      it 'verifies reboot is pending' do
        assert_reboot_pending(agent)
      end
    end
  end
end
