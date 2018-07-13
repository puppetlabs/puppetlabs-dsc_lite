require 'spec_helper_acceptance'

describe 'Reboot tests: No Invoke, Warning' do

  skip 'Implementation of this functionality depends on MODULES-6569' do
    context 'MODULES-2843 - C96007 - Apply DSC Resource that Does not Require a Reboot with Autonotify "reboot" Resource' do
      fake_name = SecureRandom.uuid
      test_file_contents = SecureRandom.uuid
      dsc_manifest = <<-MANIFEST
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


      it 'Run Puppet Apply' do
        execute_manifest(dsc_manifest, :catch_failures => true) do |result|
          # NOTE: regex includes Node\[default\]\/ when run via agent rather than apply
          assert_match(/Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
          assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
          assert_no_match(/Warning:/, result.stderr, 'Unexpected warning was detected!')
        end
      end

      it 'Verify Reboot is NOT Pending' do
        windows_agents.each do |agent|
          expect_failure('Expect that no reboot should be pending.') do
            assert_reboot_pending(agent)
          end
        end
      end

      before(:all) do
        # Workaround for https://tickets.puppetlabs.com/browse/IMAGES-539
        # 'Remove PendingFileRenameOperations registry key'
        on(windows_agents, 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /f', :accept_all_exit_codes => true)

        after(:all) do
          on(windows_agents, "rm -rf /cygdrive/c/#{fake_name}")
        end
      end
    end

    skip 'Implementation of this functionality depends on MODULES-6569' do
      context 'MODULES-2843 - C96005 - Apply DSC Resource that Requires Reboot without "reboot" Resource' do
        installed_path = get_dsc_resource_fixture_path(usage = :manifest)
        dsc_manifest = <<-MANIFEST
          dsc { 'reboot_test':
            dresource_name => 'puppetfakeresource',
            module => '#{installed_path}/1.0',
            properties => {
              importantstuff  => 'reboot',
              requirereboot   => true,
            }
          }
        MANIFEST

        warning_message = /Warning: No reboot resource found in the graph that has 'dsc_reboot' as its name/

          it 'Run Puppet Apply' do
            execute_manifest(dsc_manifest, :catch_failures => true) do |result|
              assert_match(warning_message, result.stderr, 'Expected warning was not detected!')
              assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
            end
          end

          it 'Verify Reboot is NOT Pending' do
            windows_agents.each do |agent|
              expect_failure('Expect that no reboot should be pending.') do
                assert_reboot_pending(agent)
            end
          end
        end
      end
    end

    after(:all) do
      windows_agents.each do |agent|
        teardown_dsc_resource_fixture(agent)
      end
    end

    before(:all) do
      windows_agents.each do |agent|
        setup_dsc_resource_fixture(agent)
      end
    end
  end
end
