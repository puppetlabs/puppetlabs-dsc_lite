require 'spec_helper_acceptance'

describe 'reboot exceptions' do
  skip 'Implementation of this functionality depends on MODULES-6569' do
    let(:error_message) { %r{Error:.*Found 1 dependency cycle} }

    let(:dsc_manifest) do
      <<-MANIFEST
        reboot { 'dsc_reboot':
          when => pending,
          notify => Dsc_puppetfakeresource['reboot_test']
        }
        dsc_puppetfakeresource { 'reboot_test':
          dsc_importantstuff => 'reboot',
          dsc_requirereboot => true,
        }
      MANIFEST
    end

    before(:all) do
      setup_dsc_resource_fixture(agent)
    end

    after(:all) do
      teardown_dsc_resource_fixture(agent)
    end

    context 'MODULES-2843 - when DSC resource requires reboot with inverse relationship to a "reboot" resource' do
      it 'applies manifest' do
        apply_manifest(dsc_manifest, expect_failures: true) do |result|
          expect(result.stderr).to match(%r{#{error_message}})
        end
      end

      it 'verifies reboot is not pending' do
        expect_failure('Expect that no reboot should be pending.')
      end
    end
  end
end
