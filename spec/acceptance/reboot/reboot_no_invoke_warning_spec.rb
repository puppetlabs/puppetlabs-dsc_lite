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

      windows_agents.each do |agent|
        # Workaround for https://tickets.puppetlabs.com/browse/IMAGES-539
        it 'Remove PendingFileRenameOperations registry key' do
          on(agent, 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /f', :accept_all_exit_codes => true)
        end

        it 'Run Puppet Apply' do
          on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_manifest, :acceptable_exit_codes => [0, 2]) do |result|
            # NOTE: regex includes Node\[default\]\/ when run via agent rather than apply
            assert_match(/Stage\[main\]\/Main\/Dsc\[#{fake_name}\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
            assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
            assert_no_match(/Warning:/, result.stderr, 'Unexpected warning was detected!')
          end
        end

        it 'Verify Reboot is NOT Pending' do
          expect_failure('Expect that no reboot should be pending.') do
            assert_reboot_pending(agent)
          end
        end
      end

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

      windows_agents.each do |agent|
        it 'Run Puppet Apply' do
          on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_manifest, :acceptable_exit_codes => [0, 2]) do |result|
            assert_match(warning_message, result.stderr, 'Expected warning was not detected!')
            assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
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
