require 'spec_helper_acceptance'
require 'dsc_utils'
require 'securerandom'

describe 'FM-2624 - C87654 - Apply DSC Resource Manifest with Multiple Failing DSC Resources' do
  after(:all) do
    windows_agents.each do |agent|
      uninstall_fake_reboot_resource(agent)
    end
  end

  installed_path = get_fake_reboot_resource_install_path(usage = :manifest)

  # In-line Manifest
  throw_message_1 = SecureRandom.uuid
  throw_message_2 = SecureRandom.uuid

  dsc_manifest = <<-MANIFEST
  dsc { 'throw_1':
    dsc_resource_name => 'puppetfakeresource',
    dsc_resource_module => '#{installed_path}/PuppetFakeResource',
    dsc_resource_properties => {
      ensure          => 'present',
      importantstuff  => 'foo',
      throwmessage    => '#{throw_message_1}',
    }
  }

  dsc { 'throw_2':
    dsc_resource_name => 'puppetfakeresource',
    dsc_resource_module => '#{installed_path}/PuppetFakeResource',
    dsc_resource_properties => {
      ensure          => 'present',
      importantstuff  => 'bar',
      throwmessage    => '#{throw_message_2}',
    }
  }
  MANIFEST

  # Verify
  error_msg_1 = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message_1}/
  error_msg_2 = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message_2}/
  windows_agents.each do |agent|
    context "on #{agent}" do
      install_fake_reboot_resource(agent)
      require 'pry' ; binding.pry()
      on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => 0) do |result|
        it 'Verify error is thrown' do
          assert_match(error_msg_1, result.stderr, 'Expected error was not detected!')
          assert_match(error_msg_2, result.stderr, 'Expected error was not detected!')
        end
      end
    end
  end
end
