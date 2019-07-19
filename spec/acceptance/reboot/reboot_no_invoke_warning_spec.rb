require 'spec_helper_acceptance'

describe 'reboot with no invoke, warning' do
  skip 'Implementation of this functionality depends on MODULES-6569' do
    before(:all) do
      # Workaround for https://tickets.puppetlabs.com/browse/IMAGES-539
      # 'Remove PendingFileRenameOperations registry key'
      on(windows_agents, 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /f', accept_all_exit_codes: true)
    end

    after(:all) do
      on(windows_agents, "rm -rf /cygdrive/c/#{fake_name}")
    end

    context 'MODULES-2843 - C96007 when DSC Resource does not require a reboot with autonotify "reboot" resource' do
      fake_name = SecureRandom.uuid
      test_file_contents = SecureRandom.uuid

      let(:dsc_manifest) do
        <<-MANIFEST
          dsc { '#{fake_name}':
            resource_name       => 'puppetfakeresource',
            module     => '#{installed_path}/1.0',
            properties => {
              ensure          => present,
              importantstuff  => '#{test_file_contents}',
              destinationpath => 'C:\\#{fake_name}',
            }
          }
          reboot { 'dsc_reboot':
            when => pending
          }
        MANIFEST
      end

      it 'applies manifest' do
        execute_manifest(dsc_manifest, catch_failures: true) do |result|
          # NOTE: regex includes Node\[default\]\/ when run via agent rather than apply
          # assert_match(%r{Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\/ensure\: created}, result.stdout, 'DSC Resource missing!')
          # assert_no_match(%r{Error:}, result.stderr, 'Unexpected error was detected!')
          # assert_no_match(%r{Warning:}, result.stderr, 'Unexpected warning was detected!')
          expect(result.stdout).to match(%r{Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\/ensure\: created})
          expect(result.stderr).not_to match(%r{Error:})
          expect(result.stderr).not_to match(%r{Warning:})
        end
      end

      it 'verifies reboot is not pending' do
        windows_agents.each do |agent|
          expect_failure('Expect that no reboot should be pending.') do
            assert_reboot_pending(agent)
          end
        end
      end
    end

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

      context 'MODULES-2843 - C96005 - when DSC resource requires reboot without "reboot" resource' do
        let(:installed_path) { get_dsc_resource_fixture_path(:manifest) }
        let(:warning_message) { %r{Warning: No reboot resource found in the graph that has 'dsc_reboot' as its name} }

        let(:dsc_manifest) do
          <<-MANIFEST
            dsc { 'reboot_test':
              dresource_name => 'puppetfakeresource',
              module => '#{installed_path}/1.0',
              properties => {
                importantstuff  => 'reboot',
                requirereboot   => true,
              }
            }
          MANIFEST
        end

        it 'applies manifest' do
          execute_manifest(dsc_manifest, catch_failures: true) do |result|
            expect(result.stderr).to match(%r{#{warning_message}})
            expect(result.stderr).not_to match(%r{Warning:})
          end
        end

        it 'verifies reboot is not pending' do
          windows_agents.each do |agent|
            expect_failure('Expect that no reboot should be pending.') do
              assert_reboot_pending(agent)
            end
          end
        end
      end
    end
  end
end
