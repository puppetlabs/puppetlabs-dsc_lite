require 'spec_helper_acceptance'

describe 'Negative resource tests' do

  context 'FM-2624 - Apply DSC Resource Manifest with Mix of Passing and Failing DSC Resources' do
    throw_message = SecureRandom.uuid

    dsc_manifest = <<-MANIFEST
      dsc { 'good_resource':
        resource_name => 'puppetfakeresource',
        module => '#{installed_path}/1.0',
        properties => {
          ensure          => 'present',
          importantstuff  => 'foo',
        }
      }
      
      dsc { 'throw_resource':
        resource_name => 'puppetfakeresource',
        module => '#{installed_path}/1.0',
        properties => {
          ensure          => 'present',
          importantstuff  => 'bar',
          throwmessage    => '#{throw_message}',
        }
      }
    MANIFEST

    error_msg = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message}/

    windows_agents.each do |agent|
      it 'Applies manifest with one failing resource and one successful resource' do
        on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_manifest, :acceptable_exit_codes => 6) do |result|
          assert_match(error_msg, result.stderr, 'Expected error was not detected!')
          assert_match(/Stage\[main\]\/Main\/Dsc\[good_resource\]\/ensure\: created/, result.stdout, 'DSC Resource missing!')
        end
      end
    end
  end

  context 'FM-2624 - Apply DSC Resource Manifest with Multiple Failing DSC Resources' do
    throw_message_1 = SecureRandom.uuid
    throw_message_2 = SecureRandom.uuid

    dsc_manifest = <<-MANIFEST
      dsc { 'throw_1':
        resource_name => 'puppetfakeresource',
        module => '#{installed_path}/1.0',
        properties => {
          ensure          => 'present',
          importantstuff  => 'foo',
          throwmessage    => '#{throw_message_1}',
        }
      }
      
      dsc { 'throw_2':
        resource_name => 'puppetfakeresource',
        module => '#{installed_path}/1.0',
        properties => {
          ensure          => 'present',
          importantstuff  => 'bar',
          throwmessage    => '#{throw_message_2}',
        }
      }
    MANIFEST

    error_msg_1 = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message_1}/
    error_msg_2 = /Error: PowerShell DSC resource PuppetFakeResource  failed to execute Set-TargetResource functionality with error message: #{throw_message_2}/

    windows_agents.each do |agent|
      it 'Applies manifest with multiple failing resources' do
        on(agent, puppet('apply --detailed-exitcodes'), :stdin => dsc_manifest, :acceptable_exit_codes => 4) do |result|
          assert_match(error_msg_1, result.stderr, 'Expected error was not detected!')
          assert_match(error_msg_2, result.stderr, 'Expected error was not detected!')
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

